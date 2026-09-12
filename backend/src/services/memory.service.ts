import OpenAI from 'openai';
import { env } from '../config/env';
import { badRequest } from '../utils/errors';
import { supabase } from '../config/supabase';
import { listMessages } from './message.service';

// Anchor's reflection pass: turns recent conversation into durable memory
// (user_patterns). Modelled on Zaasu's per-conversation extractor but fixing its
// defects (see hive notes): the model PROPOSES, code RECONCILES; merge is a
// capped dedupe into the single user_patterns row; timestamps stamped in code;
// evidence-gated so it does not invent traits; the model never computes numbers.
// Meant to run DEBOUNCED (session boundary / every few turns), not per message.

const MEMORY_SYS = `You extract durable, useful memory about how this specific person commits and where they overcommit, from a recent conversation.
Return ONLY JSON: {"pitfalls":[],"priorities":[],"habits":[],"working_style":null}.
Rules:
- Include an item ONLY if the conversation clearly evidences it. If nothing new is evidenced, return empty arrays and null.
- Each item is a short phrase (max ~10 words). No numbers you had to calculate, no invented facts.
- pitfalls = recurring ways they overcommit or self-sabotage. priorities = what they value most. habits = regular behaviours. working_style = one short phrase or null.
- Do not restate generic advice. Only things true of THIS person.`;

let client: OpenAI | null = null;
function openai(): OpenAI {
  if (!env.openaiApiKey) throw badRequest('Memory is unavailable: OPENAI_API_KEY is not configured.');
  client ??= new OpenAI({ apiKey: env.openaiApiKey, baseURL: env.openaiBaseUrl });
  return client;
}

interface PatternRow {
  id: string;
  pitfalls: unknown;
  priorities: unknown;
  habits: unknown;
  working_style: string | null;
}

async function latest(userId: string): Promise<PatternRow | null> {
  const { data } = await supabase
    .from('user_patterns')
    .select('id, pitfalls, priorities, habits, working_style')
    .eq('user_id', userId)
    .order('extracted_at', { ascending: false })
    .limit(1)
    .maybeSingle();
  return (data as PatternRow) ?? null;
}

const asList = (v: unknown): string[] => (Array.isArray(v) ? v.map(String) : []);

// dedupe case-insensitively, keep first spelling, cap length
function mergeCapped(existing: string[], proposed: string[], cap = 8): string[] {
  const out: string[] = [];
  const seen = new Set<string>();
  for (const item of [...existing, ...proposed]) {
    const key = item.trim().toLowerCase();
    if (!key || seen.has(key)) continue;
    seen.add(key);
    out.push(item.trim());
    if (out.length >= cap) break;
  }
  return out;
}

export interface ReflectResult {
  updated: boolean;
  pitfalls: string[];
  priorities: string[];
  habits: string[];
  working_style: string | null;
}

export async function reflect(userId: string): Promise<ReflectResult> {
  const [msgs, row] = await Promise.all([listMessages(userId, 20), latest(userId)]);
  const userTurns = msgs.filter((m) => m.role === 'user');

  const existing = {
    pitfalls: asList(row?.pitfalls),
    priorities: asList(row?.priorities),
    habits: asList(row?.habits),
    working_style: row?.working_style ?? null,
  };

  // cheap guard: not enough new conversation to reflect on
  if (userTurns.length < 2) {
    return { updated: false, ...existing };
  }

  const res = await openai().chat.completions.create({
    model: env.openaiModel,
    temperature: 0.2,
    response_format: { type: 'json_object' },
    messages: [
      { role: 'system', content: MEMORY_SYS },
      {
        role: 'user',
        content: JSON.stringify({
          existing,
          recent_conversation: msgs.map((m) => ({ role: m.role, content: m.content })),
        }),
      },
    ],
  });

  let proposed: { pitfalls?: unknown; priorities?: unknown; habits?: unknown; working_style?: unknown } = {};
  try {
    proposed = JSON.parse(res.choices[0]?.message?.content ?? '{}');
  } catch {
    return { updated: false, ...existing };
  }

  const merged = {
    pitfalls: mergeCapped(existing.pitfalls, asList(proposed.pitfalls)),
    priorities: mergeCapped(existing.priorities, asList(proposed.priorities)),
    habits: mergeCapped(existing.habits, asList(proposed.habits)),
    working_style: (typeof proposed.working_style === 'string' && proposed.working_style.trim())
      ? proposed.working_style.trim()
      : existing.working_style,
  };

  // upsert into the single latest row (timestamp stamped in code, not by the model)
  const payload = { ...merged, extracted_at: new Date().toISOString() };
  if (row) {
    await supabase.from('user_patterns').update(payload).eq('id', row.id);
  } else {
    await supabase.from('user_patterns').insert({ user_id: userId, source: 'observed', ...payload });
  }

  return { updated: true, ...merged };
}

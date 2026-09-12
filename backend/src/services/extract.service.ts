import OpenAI from 'openai';
import { env } from '../config/env';
import { badRequest } from '../utils/errors';
import { upsertUserPatterns, type UserPatterns } from './pattern.service';

// "Bring your history": the user pastes a reply from ChatGPT/Claude; we turn that
// free text into the structured user_patterns shape (spec §7) and store it.
// Everything is jsonb-friendly, so a messy paste never blocks the import.

const EXTRACT_RULES = `You extract a person's working profile from text they pasted
from another AI assistant (or wrote themselves). Return ONLY JSON with these keys:

{
  "personality":      { ... }  // object: traits, drivers, risks. Free-form keys.
  "pitfalls":         [ ... ]  // array of short strings: how they self-sabotage
  "working_style":    "..."    // one or two sentences
  "current_projects": [ ... ]  // array of short strings
  "baseline_load":    "..."    // one short sentence on how loaded they already are
  "priorities":       [ ... ]  // array of short strings, most important first
  "habits":           [ ... ]  // array of short strings, include timing if stated
                               // e.g. "orders food ~Sat 6pm", "gym Mon/Wed/Fri"
}

Rules: infer only what the text supports; never invent specifics. Use [] or "" when
absent. Keep every string short and concrete. No markdown, no commentary.`;

function client(): OpenAI {
  if (!env.openaiApiKey) {
    throw badRequest('Import is unavailable: OPENAI_API_KEY is not configured.');
  }
  return new OpenAI({ apiKey: env.openaiApiKey, baseURL: env.openaiBaseUrl });
}

function asStringArray(v: unknown): string[] {
  if (!Array.isArray(v)) return [];
  return v.map((x) => (typeof x === 'string' ? x : JSON.stringify(x))).filter(Boolean);
}

export interface ExtractInput {
  source: 'chatgpt' | 'claude' | 'upload' | 'fresh';
  raw_text: string;
}

/** Extracts the paste into user_patterns and persists it. Raw text is kept so we
 *  can re-extract later without asking the person to paste again. */
export async function extractAndStore(
  userId: string,
  input: ExtractInput,
): Promise<UserPatterns> {
  const text = input.raw_text.trim();
  if (!text) throw badRequest('Nothing to extract: raw_text is empty.');

  const res = await client().chat.completions.create({
    model: env.openaiModel,
    temperature: 0.2,
    response_format: { type: 'json_object' },
    messages: [
      { role: 'system', content: EXTRACT_RULES },
      { role: 'user', content: text.slice(0, 100_000) },
    ],
  });

  const raw = res.choices[0]?.message?.content ?? '{}';
  let parsed: Record<string, unknown>;
  try {
    parsed = JSON.parse(raw) as Record<string, unknown>;
  } catch {
    throw new Error(`Extraction returned invalid JSON: ${raw.slice(0, 200)}`);
  }

  return upsertUserPatterns(userId, {
    personality:
      parsed.personality && typeof parsed.personality === 'object'
        ? (parsed.personality as Record<string, unknown>)
        : {},
    pitfalls: asStringArray(parsed.pitfalls),
    working_style: typeof parsed.working_style === 'string' ? parsed.working_style : undefined,
    current_projects: asStringArray(parsed.current_projects),
    baseline_load: typeof parsed.baseline_load === 'string' ? parsed.baseline_load : undefined,
    priorities: asStringArray(parsed.priorities),
    habits: asStringArray(parsed.habits),
    source: input.source,
    raw_import: text,
  });
}

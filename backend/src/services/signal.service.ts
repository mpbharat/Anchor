import { supabase } from '../config/supabase';

// load_signals (canonical): source calendar|gmail, kind event|ask|purchase.
export interface LoadSignal {
  id: string;
  user_id: string;
  source: string;
  kind: string;
  title: string | null;
  merchant: string | null;
  amount: number | null;
  category: string | null;
  occurred_at: string | null;
}

// POST /signals — push a parsed purchase / event / incoming ask (Maria).
export async function ingestSignal(
  userId: string,
  input: {
    source: 'calendar' | 'gmail';
    kind: 'event' | 'ask' | 'purchase';
    title?: string;
    merchant?: string;
    amount?: number;
    category?: string;
    occurred_at?: string;
  },
): Promise<LoadSignal> {
  const { data, error } = await supabase
    .from('load_signals')
    .insert({
      user_id: userId,
      source: input.source,
      kind: input.kind,
      title: input.title ?? null,
      merchant: input.merchant ?? null,
      amount: input.amount ?? null,
      category: input.category ?? null,
      occurred_at: input.occurred_at ?? new Date().toISOString(),
    })
    .select('*')
    .single();
  if (error) throw new Error(error.message);
  return data as LoadSignal;
}

export async function listSignals(userId: string, limit = 100): Promise<LoadSignal[]> {
  const { data, error } = await supabase
    .from('load_signals')
    .select('*')
    .eq('user_id', userId)
    .order('occurred_at', { ascending: false })
    .limit(limit);
  if (error) throw new Error(error.message);
  return (data ?? []) as LoadSignal[];
}

// GET /users/:id/load — current load + spend totals for the AI to weigh.
export async function getLoadSummary(userId: string): Promise<{
  commitments: { id: string; title: string; metric: string; current_value: number; target_value: number; unit: string | null }[];
  spend_by_category: Record<string, number>;
  event_count: number;
}> {
  const { data: commitments } = await supabase
    .from('commitments')
    .select('id, title, metric, current_value, target_value, unit, week_id, status')
    .eq('user_id', userId)
    .in('status', ['on_record', 'due', 'done']);

  const { data: signals } = await supabase
    .from('load_signals')
    .select('kind, amount, category')
    .eq('user_id', userId);

  const spend: Record<string, number> = {};
  let events = 0;
  for (const s of signals ?? []) {
    if (s.kind === 'purchase' && s.amount) {
      const cat = (s.category as string) ?? 'uncategorised';
      spend[cat] = (spend[cat] ?? 0) + Number(s.amount);
    }
    if (s.kind === 'event') events += 1;
  }

  return {
    commitments: (commitments ?? []).map((c) => ({
      id: c.id as string,
      title: c.title as string,
      metric: c.metric as string,
      current_value: Number(c.current_value),
      target_value: Number(c.target_value),
      unit: (c.unit as string) ?? null,
    })),
    spend_by_category: spend,
    event_count: events,
  };
}

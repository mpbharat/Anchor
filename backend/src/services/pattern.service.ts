import { supabase } from '../config/supabase';
import { notFound } from '../utils/errors';

// "Bring your history" — user_patterns. The canonical schema has no unique index
// on user_id, so we manually replace the existing row (keep one per user).
export interface UserPatterns {
  id: string;
  user_id: string;
  personality: Record<string, unknown> | null;
  pitfalls: unknown[] | null;
  working_style: string | null;
  current_projects: unknown[] | null;
  baseline_load: string | null;
  priorities: unknown[] | null;
  habits: unknown[] | null;
  source: string | null;
  raw_import: string | null;
  extracted_at: string;
}

export interface UserPatternsInput {
  personality?: Record<string, unknown>;
  pitfalls?: unknown[];
  working_style?: string;
  current_projects?: unknown[];
  baseline_load?: string;
  priorities?: unknown[];
  habits?: unknown[];
  source: string;
  raw_import?: string;
}

export async function upsertUserPatterns(
  userId: string,
  input: UserPatternsInput,
): Promise<UserPatterns> {
  const row = {
    user_id: userId,
    personality: input.personality ?? {},
    pitfalls: input.pitfalls ?? [],
    working_style: input.working_style ?? null,
    current_projects: input.current_projects ?? [],
    baseline_load: input.baseline_load ?? null,
    priorities: input.priorities ?? [],
    habits: input.habits ?? [],
    source: input.source,
    raw_import: input.raw_import ?? null,
    extracted_at: new Date().toISOString(),
  };

  const { data: existing } = await supabase
    .from('user_patterns')
    .select('id')
    .eq('user_id', userId)
    .maybeSingle();

  const query = existing
    ? supabase.from('user_patterns').update(row).eq('user_id', userId)
    : supabase.from('user_patterns').insert(row);
  const { data, error } = await query.select('*').single();
  if (error) throw new Error(error.message);
  return data as UserPatterns;
}

export async function getUserPatterns(userId: string): Promise<UserPatterns> {
  const { data, error } = await supabase
    .from('user_patterns')
    .select('*')
    .eq('user_id', userId)
    .maybeSingle();
  if (error) throw new Error(error.message);
  if (!data) throw notFound('No history imported yet');
  return data as UserPatterns;
}

export async function clearUserPatterns(userId: string): Promise<void> {
  const { error } = await supabase.from('user_patterns').delete().eq('user_id', userId);
  if (error) throw new Error(error.message);
}

export interface Pattern {
  id: string;
  user_id: string;
  commitment_id: string | null;
  kind: string;
  descriptor: string | null;
  schedule: string | null;
  confidence: number | null;
  last_seen: string | null;
  source: string | null;
}

export async function listPatterns(userId: string): Promise<Pattern[]> {
  const { data, error } = await supabase
    .from('patterns')
    .select('*')
    .eq('user_id', userId)
    .order('confidence', { ascending: false });
  if (error) throw new Error(error.message);
  return (data ?? []) as Pattern[];
}

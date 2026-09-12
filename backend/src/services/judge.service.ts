import { supabase } from '../config/supabase';
import * as brain from './brain.service';

// The AI (Bharat, ai/judge.ts) owns the reasoning; this endpoint is the seam that
// records every pass to `judgments` and schedules a nudge when the verdict warrants.
// Callers pass the AI's decision (verdict/spoken/reasoning/weighed_against); if a
// budget signal is passed without a verdict, a deterministic breach check runs.

export interface Judgment {
  id: string;
  user_id: string;
  week_id: string | null;
  trigger: string | null;
  source: string;
  verdict: string; // nudge | stay_silent | declined | allowed | swapped
  reasoning: string | null;
  weighed_against: unknown[] | null;
  overridden: boolean;
  created_at: string;
}

export interface JudgeInput {
  source: 'voice' | 'email' | 'pattern' | 'calendar';
  request?: string;
  trigger?: string;
  week_id?: string;
  verdict?: string;
  spoken?: string;
  reasoning?: string;
  weighed_against?: unknown[];
  suggested_action?: string;
  // deterministic budget fallback
  commitment_id?: string;
  amount?: number;
}

export interface JudgeResult {
  verdict: string;
  spoken: string | null;
  reasoning: string | null;
  weighed_against: unknown[];
  suggested_action: string | null;
  judgment: Judgment;
  nudge: import('./nudge.service').Nudge | null;
}

export async function judge(userId: string, input: JudgeInput): Promise<JudgeResult> {
  let verdict = input.verdict;
  let reasoning = input.reasoning ?? null;
  let spoken = input.spoken ?? null;
  let weighed: unknown[] = input.weighed_against ?? [];

  // Deterministic fallback: only nudge on a real budget breach.
  if (!verdict && input.commitment_id && input.amount != null) {
    const { data: c } = await supabase
      .from('commitments')
      .select('title, current_value, target_value, metric')
      .eq('id', input.commitment_id)
      .eq('user_id', userId)
      .maybeSingle();
    if (c && c.metric === 'amount' && Number(c.current_value) + input.amount > Number(c.target_value)) {
      verdict = 'nudge';
      spoken = spoken ?? `That puts you over "${c.title}". Worth a pause — is this one you want?`;
      reasoning = reasoning ?? `${c.current_value} + ${input.amount} exceeds cap ${c.target_value}.`;
    } else {
      verdict = 'stay_silent';
      reasoning = reasoning ?? 'Within the commitment. Logged, not shown.';
    }
  }
  // AI judgment: no verdict supplied but a request is present -> reason with the model.
  if (!verdict && input.request) {
    const v = await brain.reason(userId, input.request);
    verdict = v.verdict;
    spoken = v.spoken;
    reasoning = v.reasoning;
    weighed = v.weighed_against;
  }

  verdict = verdict ?? 'stay_silent';

  const { data, error } = await supabase
    .from('judgments')
    .insert({
      user_id: userId,
      week_id: input.week_id ?? null,
      trigger: input.trigger ?? input.request ?? null,
      source: input.source,
      verdict,
      reasoning,
      weighed_against: weighed,
    })
    .select('*')
    .single();
  if (error) throw new Error(error.message);
  const judgment = data as Judgment;

  let nudge: import('./nudge.service').Nudge | null = null;
  if (verdict === 'nudge') {
    const { scheduleNudge } = await import('./nudge.service');
    nudge = await scheduleNudge(userId, {
      commitment_id: input.commitment_id,
      channel: 'push',
      title: 'Anchor',
      body: spoken ?? reasoning ?? 'Anchor.',
      fire_at: new Date().toISOString(),
    });
  }

  return {
    verdict,
    spoken,
    reasoning,
    weighed_against: (judgment.weighed_against as unknown[]) ?? [],
    suggested_action: input.suggested_action ?? null,
    judgment,
    nudge,
  };
}

// GET /silence-log — everything Anchor chose not to say.
export async function silenceLog(userId: string): Promise<Judgment[]> {
  const { data, error } = await supabase
    .from('judgments')
    .select('*')
    .eq('user_id', userId)
    .eq('verdict', 'stay_silent')
    .order('created_at', { ascending: false });
  if (error) throw new Error(error.message);
  return (data ?? []) as Judgment[];
}

export async function listJudgments(userId: string): Promise<Judgment[]> {
  const { data, error } = await supabase
    .from('judgments')
    .select('*')
    .eq('user_id', userId)
    .order('created_at', { ascending: false });
  if (error) throw new Error(error.message);
  return (data ?? []) as Judgment[];
}

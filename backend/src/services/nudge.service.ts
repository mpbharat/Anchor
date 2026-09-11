import { supabase } from '../config/supabase';
import { notFound } from '../utils/errors';

// nudges (canonical): fire_at, channel push|watch, status scheduled|sent|acted|snoozed.
export interface Nudge {
  id: string;
  user_id: string;
  commitment_id: string | null;
  fire_at: string | null;
  channel: string;
  title: string | null;
  body: string | null;
  status: string;
  sent_at: string | null;
}

export interface ScheduleNudgeInput {
  commitment_id?: string;
  fire_at?: string;
  channel?: 'push' | 'watch';
  title?: string;
  body: string;
}

// POST /nudges — schedule a nudge (also used by the judge engine).
export async function scheduleNudge(userId: string, input: ScheduleNudgeInput): Promise<Nudge> {
  const { data, error } = await supabase
    .from('nudges')
    .insert({
      user_id: userId,
      commitment_id: input.commitment_id ?? null,
      fire_at: input.fire_at ?? new Date().toISOString(),
      channel: input.channel ?? 'push',
      title: input.title ?? 'Anchor',
      body: input.body,
      status: 'scheduled',
    })
    .select('*')
    .single();
  if (error) throw new Error(error.message);
  return data as Nudge;
}

export async function listNudges(userId: string, includeSent = false): Promise<Nudge[]> {
  let query = supabase
    .from('nudges')
    .select('*')
    .eq('user_id', userId)
    .order('fire_at', { ascending: true });
  if (!includeSent) query = query.eq('status', 'scheduled');
  const { data, error } = await query;
  if (error) throw new Error(error.message);
  return (data ?? []) as Nudge[];
}

// PUT /nudges/:id/respond — "On it" / "Snooze" from the wrist.
export async function respondToNudge(
  userId: string,
  nudgeId: string,
  action: 'on_it' | 'snooze',
  snoozeMinutes = 30,
): Promise<Nudge> {
  const { data: nudge, error } = await supabase
    .from('nudges')
    .select('*')
    .eq('id', nudgeId)
    .eq('user_id', userId)
    .maybeSingle();
  if (error) throw new Error(error.message);
  if (!nudge) throw notFound('Nudge not found');

  const updates =
    action === 'on_it'
      ? { status: 'acted' }
      : { status: 'snoozed', fire_at: new Date(Date.now() + snoozeMinutes * 60000).toISOString() };

  const { data, error: updErr } = await supabase
    .from('nudges')
    .update(updates)
    .eq('id', nudgeId)
    .select('*')
    .single();
  if (updErr) throw new Error(updErr.message);
  return data as Nudge;
}

// For the nudge scheduler (event day): scheduled nudges due now.
export async function listDue(limit = 100): Promise<Nudge[]> {
  const nowIso = new Date().toISOString();
  const { data, error } = await supabase
    .from('nudges')
    .select('*')
    .eq('status', 'scheduled')
    .lte('fire_at', nowIso)
    .order('fire_at', { ascending: true })
    .limit(limit);
  if (error) throw new Error(error.message);
  return (data ?? []) as Nudge[];
}

export async function markSent(nudgeId: string): Promise<void> {
  await supabase
    .from('nudges')
    .update({ status: 'sent', sent_at: new Date().toISOString() })
    .eq('id', nudgeId);
}

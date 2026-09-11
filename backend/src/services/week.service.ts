import { supabase } from '../config/supabase';
import { badRequest, notFound } from '../utils/errors';
import { addDays, currentWeekStart, isoWeekNumber } from '../utils/time';
import { getUser, getSettings } from './user.service';

export interface Week {
  id: string;
  user_id: string;
  week_start: string;
  week_number: number;
  status: string;
}

export interface Commitment {
  id: string;
  user_id: string;
  week_id: string;
  title: string;
  kind: string;
  metric: string;
  target_value: number;
  unit: string | null;
  period: string | null;
  current_value: number;
  position: number;
  status: string; // on_record | due | done | carried | dropped
  carried_from: string | null;
  completed_at: string | null;
}

const LIVE = ['on_record', 'due', 'done'];

export async function getOrCreateCurrentWeek(userId: string): Promise<Week> {
  const user = await getUser(userId);
  const weekStart = currentWeekStart(user.timezone || 'Asia/Dubai');

  const { data: existing, error } = await supabase
    .from('weeks')
    .select('*')
    .eq('user_id', userId)
    .eq('week_start', weekStart)
    .maybeSingle();
  if (error) throw new Error(error.message);
  if (existing) return existing as Week;

  const { data, error: insErr } = await supabase
    .from('weeks')
    .insert({ user_id: userId, week_start: weekStart, week_number: isoWeekNumber(weekStart), status: 'active' })
    .select('*')
    .single();
  if (insErr) throw new Error(insErr.message);
  return data as Week;
}

export async function getWeek(userId: string, weekId: string): Promise<Week> {
  const { data, error } = await supabase
    .from('weeks')
    .select('*')
    .eq('id', weekId)
    .eq('user_id', userId)
    .maybeSingle();
  if (error) throw new Error(error.message);
  if (!data) throw notFound('Week not found');
  return data as Week;
}

export async function listCommitments(weekId: string): Promise<Commitment[]> {
  const { data, error } = await supabase
    .from('commitments')
    .select('*')
    .eq('week_id', weekId)
    .order('position', { ascending: true });
  if (error) throw new Error(error.message);
  return (data ?? []) as Commitment[];
}

// GET /weeks/current/commitments — the Load.
export async function getCurrentLoad(userId: string): Promise<{
  week: Week;
  cap: number;
  loaded: number;
  commitments: Commitment[];
}> {
  const [settings, week] = await Promise.all([getSettings(userId), getOrCreateCurrentWeek(userId)]);
  const commitments = await listCommitments(week.id);
  const loaded = commitments.filter((c) => LIVE.includes(c.status)).length;
  return { week, cap: settings.cap ?? 4, loaded, commitments };
}

function kept(c: Commitment): boolean {
  if (c.status === 'done') return true;
  if (c.status === 'carried' || c.status === 'dropped') return false;
  return Number(c.current_value) >= Number(c.target_value);
}

// GET /weeks/:id/review — end-of-week standing (persists a weekly_reviews row).
export async function getReview(userId: string, weekId: string): Promise<{
  week: Week;
  kept_count: number;
  total_count: number;
  anchor_message: string;
  commitments: Commitment[];
}> {
  const week = await getWeek(userId, weekId);
  const commitments = await listCommitments(week.id);
  const counted = commitments.filter((c) => c.status !== 'dropped' && c.status !== 'carried');
  const keptCount = counted.filter(kept).length;
  const total = counted.length;
  const missed = total - keptCount;
  const anchorMessage =
    total === 0
      ? 'No commitments on record this week.'
      : missed === 0
        ? `You kept all ${total}. Clean week.`
        : `You kept ${keptCount} of ${total}. The ${missed === 1 ? 'one you missed' : `${missed} you missed`} — that's a miss, not who you are. Same next week, or swap one?`;

  // No unique constraint on week_id in the canonical schema — replace manually.
  const { data: existing } = await supabase
    .from('weekly_reviews')
    .select('id')
    .eq('week_id', week.id)
    .maybeSingle();
  const payload = { user_id: userId, week_id: week.id, kept_count: keptCount, total_count: total, anchor_message: anchorMessage };
  const q = existing
    ? supabase.from('weekly_reviews').update(payload).eq('id', existing.id)
    : supabase.from('weekly_reviews').insert(payload);
  const { data, error } = await q.select('*').single();
  if (error) throw new Error(error.message);

  return {
    week,
    kept_count: (data as { kept_count: number }).kept_count,
    total_count: (data as { total_count: number }).total_count,
    anchor_message: (data as { anchor_message: string }).anchor_message,
    commitments,
  };
}

// Settle live commitments, close the week, roll into next (same four or fresh).
export async function closeWeek(
  userId: string,
  weekId: string,
  mode: 'same' | 'fresh',
  carryCommitmentIds?: string[],
): Promise<{ closed: Week; next: Week; commitments: Commitment[] }> {
  const week = await getWeek(userId, weekId);
  if (week.status === 'closed') throw badRequest('Week is already closed');

  await getReview(userId, weekId);
  const commitments = await listCommitments(week.id);

  for (const c of commitments) {
    if (!LIVE.includes(c.status)) continue;
    const status = kept(c) ? 'done' : 'carried';
    const { error } = await supabase
      .from('commitments')
      .update({ status, completed_at: status === 'done' ? new Date().toISOString() : null })
      .eq('id', c.id);
    if (error) throw new Error(error.message);
  }

  const { error: closeErr } = await supabase.from('weeks').update({ status: 'closed' }).eq('id', week.id);
  if (closeErr) throw new Error(closeErr.message);

  const nextStart = addDays(week.week_start, 7);
  const { data: existingNext } = await supabase
    .from('weeks')
    .select('*')
    .eq('user_id', userId)
    .eq('week_start', nextStart)
    .maybeSingle();
  let next = existingNext as Week | null;
  if (!next) {
    const { data, error } = await supabase
      .from('weeks')
      .insert({ user_id: userId, week_start: nextStart, week_number: isoWeekNumber(nextStart), status: 'active' })
      .select('*')
      .single();
    if (error) throw new Error(error.message);
    next = data as Week;
  }

  if (mode === 'same' || (carryCommitmentIds && carryCommitmentIds.length > 0)) {
    const toCarry = commitments.filter(
      (c) => c.status !== 'dropped' && (mode === 'same' || carryCommitmentIds!.includes(c.id)),
    );
    for (const c of toCarry) {
      const { error } = await supabase.from('commitments').insert({
        user_id: userId,
        week_id: next.id,
        title: c.title,
        kind: c.kind,
        metric: c.metric,
        target_value: c.target_value,
        unit: c.unit,
        period: c.period,
        position: c.position,
        carried_from: c.id,
        status: 'on_record',
      });
      if (error) throw new Error(error.message);
    }
  }

  return { closed: { ...week, status: 'closed' }, next, commitments: await listCommitments(next.id) };
}

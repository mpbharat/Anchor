import { supabase } from '../config/supabase';
import { badRequest, conflict, notFound } from '../utils/errors';
import { getCurrentLoad, type Commitment } from './week.service';

const LIVE = ['on_record', 'due', 'done'];

export interface Intention {
  id: string;
  commitment_id: string;
  wish: string | null;
  obstacle: string | null;
  if_trigger: string | null;
  then_action: string | null;
}

export interface CommitmentInput {
  title: string;
  kind?: string;
  metric?: string;
  target_value?: number;
  unit?: string;
  period?: string;
  wish?: string;
  obstacle?: string;
  if_trigger?: string;
  then_action?: string;
}

export interface CommitmentWithIntention extends Commitment {
  intention: Intention | null;
}

async function getIntention(commitmentId: string): Promise<Intention | null> {
  const { data, error } = await supabase
    .from('intentions')
    .select('*')
    .eq('commitment_id', commitmentId)
    .maybeSingle();
  if (error) throw new Error(error.message);
  return (data as Intention) ?? null;
}

// POST /commitments — add one of the four. A 5th returns the "no".
export async function createCommitment(
  userId: string,
  input: CommitmentInput,
): Promise<
  | { decision: 'added'; commitment: CommitmentWithIntention }
  | { decision: 'no'; loaded: number; cap: number; commitments: Commitment[] }
> {
  const { week, cap, loaded, commitments } = await getCurrentLoad(userId);
  if (loaded >= cap) {
    return { decision: 'no', loaded, cap, commitments: commitments.filter((c) => LIVE.includes(c.status)) };
  }

  const used = new Set(commitments.filter((c) => LIVE.includes(c.status)).map((c) => c.position));
  let position = 1;
  while (used.has(position)) position += 1;

  const { data, error } = await supabase
    .from('commitments')
    .insert({
      user_id: userId,
      week_id: week.id,
      title: input.title,
      kind: input.kind ?? 'oneoff',
      metric: input.metric ?? 'boolean',
      target_value: input.target_value ?? 1,
      unit: input.unit ?? null,
      period: input.period ?? null,
      position,
      status: 'on_record',
    })
    .select('*')
    .single();
  if (error) throw new Error(error.message);
  const commitment = data as Commitment;

  let intention: Intention | null = null;
  if (input.wish || input.obstacle || input.if_trigger || input.then_action) {
    const { data: intData, error: intErr } = await supabase
      .from('intentions')
      .insert({
        commitment_id: commitment.id,
        wish: input.wish ?? null,
        obstacle: input.obstacle ?? null,
        if_trigger: input.if_trigger ?? null,
        then_action: input.then_action ?? null,
      })
      .select('*')
      .single();
    if (intErr) throw new Error(intErr.message);
    intention = intData as Intention;
  }

  return { decision: 'added', commitment: { ...commitment, intention } };
}

export async function getCommitment(userId: string, id: string): Promise<CommitmentWithIntention> {
  const { data, error } = await supabase
    .from('commitments')
    .select('*')
    .eq('id', id)
    .eq('user_id', userId)
    .maybeSingle();
  if (error) throw new Error(error.message);
  if (!data) throw notFound('Commitment not found');
  return { ...(data as Commitment), intention: await getIntention(id) };
}

// PUT /commitments/:id/checkin — tick progress / done / miss.
export async function checkin(
  userId: string,
  id: string,
  input: { kind: 'progress' | 'done' | 'miss'; value?: number; note?: string },
): Promise<CommitmentWithIntention> {
  const commitment = await getCommitment(userId, id);
  if (!LIVE.includes(commitment.status)) throw badRequest(`Commitment is ${commitment.status}`);

  const { error: ciErr } = await supabase.from('check_ins').insert({
    commitment_id: id,
    kind: input.kind,
    value: input.value ?? null,
    note: input.note ?? null,
  });
  if (ciErr) throw new Error(ciErr.message);

  const updates: Record<string, unknown> = {};
  if (input.kind === 'done') {
    updates.status = 'done';
    updates.current_value = commitment.target_value;
    updates.completed_at = new Date().toISOString();
  } else if (input.kind === 'progress') {
    const inc = input.value ?? 1;
    const next = Math.min(Number(commitment.current_value) + inc, Number(commitment.target_value));
    updates.current_value = next;
    if (next >= Number(commitment.target_value)) {
      updates.status = 'done';
      updates.completed_at = new Date().toISOString();
    }
  }
  if (Object.keys(updates).length > 0) {
    const { error } = await supabase.from('commitments').update(updates).eq('id', id);
    if (error) throw new Error(error.message);
  }
  return getCommitment(userId, id);
}

export async function updateCommitment(
  userId: string,
  id: string,
  updates: Partial<CommitmentInput>,
): Promise<CommitmentWithIntention> {
  const existing = await getCommitment(userId, id);
  const fields: Record<string, unknown> = {};
  for (const k of ['title', 'kind', 'metric', 'target_value', 'unit', 'period'] as const) {
    if (updates[k] !== undefined) fields[k] = updates[k];
  }
  if (Object.keys(fields).length > 0) {
    const { error } = await supabase.from('commitments').update(fields).eq('id', id);
    if (error) throw new Error(error.message);
  }

  const intentionFields: Record<string, unknown> = {};
  for (const k of ['wish', 'obstacle', 'if_trigger', 'then_action'] as const) {
    if (updates[k] !== undefined) intentionFields[k] = updates[k];
  }
  if (Object.keys(intentionFields).length > 0) {
    if (existing.intention) {
      const { error } = await supabase.from('intentions').update(intentionFields).eq('commitment_id', id);
      if (error) throw new Error(error.message);
    } else {
      const { error } = await supabase.from('intentions').insert({ commitment_id: id, ...intentionFields });
      if (error) throw new Error(error.message);
    }
  }
  return getCommitment(userId, id);
}

export async function dropCommitment(userId: string, id: string): Promise<Commitment> {
  const c = await getCommitment(userId, id);
  if (!LIVE.includes(c.status)) throw badRequest(`Commitment is ${c.status}`);
  const { data, error } = await supabase
    .from('commitments')
    .update({ status: 'dropped' })
    .eq('id', id)
    .select('*')
    .single();
  if (error) throw new Error(error.message);
  return data as Commitment;
}

export async function swapCommitment(
  userId: string,
  id: string,
  replacement: CommitmentInput,
): Promise<{ swapped_out: Commitment; swapped_in: CommitmentWithIntention }> {
  const old = await getCommitment(userId, id);
  if (!LIVE.includes(old.status)) throw badRequest(`Commitment is ${old.status}`);

  const { data: outData, error: outErr } = await supabase
    .from('commitments')
    .update({ status: 'dropped' })
    .eq('id', id)
    .select('*')
    .single();
  if (outErr) throw new Error(outErr.message);

  const created = await createCommitment(userId, replacement);
  if (created.decision !== 'added') throw conflict('Could not place the replacement commitment');
  return { swapped_out: outData as Commitment, swapped_in: created.commitment };
}

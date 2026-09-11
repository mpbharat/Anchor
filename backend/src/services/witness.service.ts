import { supabase } from '../config/supabase';
import { notFound } from '../utils/errors';

// witnesses (canonical): name, contact, channel email|whatsapp, status invited.
export interface Witness {
  id: string;
  user_id: string;
  name: string;
  contact: string | null;
  channel: string;
  status: string;
}

export async function listWitnesses(userId: string): Promise<Witness[]> {
  const { data, error } = await supabase.from('witnesses').select('*').eq('user_id', userId);
  if (error) throw new Error(error.message);
  return (data ?? []) as Witness[];
}

export async function addWitness(
  userId: string,
  input: { name: string; contact?: string; channel?: 'email' | 'whatsapp' },
): Promise<Witness> {
  const { data, error } = await supabase
    .from('witnesses')
    .insert({
      user_id: userId,
      name: input.name,
      contact: input.contact ?? null,
      channel: input.channel ?? 'email',
      status: 'invited',
    })
    .select('*')
    .single();
  if (error) throw new Error(error.message);
  return data as Witness;
}

export async function removeWitness(userId: string, id: string): Promise<void> {
  const { data, error } = await supabase
    .from('witnesses')
    .delete()
    .eq('id', id)
    .eq('user_id', userId)
    .select('id');
  if (error) throw new Error(error.message);
  if (!data || data.length === 0) throw notFound('Witness not found');
}

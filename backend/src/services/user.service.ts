import { supabase } from '../config/supabase';
import { badRequest, notFound } from '../utils/errors';

export interface User {
  id: string;
  email: string | null;
  first_name: string | null;
  timezone: string;
  comm_style: string | null;
  onboarding_status: string;
  is_fresh_start: boolean;
  created_at: string;
}

export interface UserSettings {
  user_id: string;
  review_day: string;
  review_time: string;
  nudge_style: string;
  quiet_hours: Record<string, unknown> | null;
  cap: number;
}

// The signup trigger may not exist in this project's DB (the canonical migration
// leaves it out), so ensure the profile + settings rows on first touch.
async function ensureUser(id: string, email?: string | null): Promise<void> {
  const { data } = await supabase.from('users').select('id').eq('id', id).maybeSingle();
  if (!data) {
    await supabase.from('users').insert({ id, email: email ?? null });
    await supabase.from('user_settings').insert({ user_id: id });
  }
}

export async function getUser(id: string, email?: string | null): Promise<User> {
  await ensureUser(id, email);
  const { data, error } = await supabase.from('users').select('*').eq('id', id).maybeSingle();
  if (error) throw new Error(error.message);
  if (!data) throw notFound('User not found');
  return data as User;
}

export async function updateUser(
  id: string,
  updates: Partial<Pick<User, 'first_name' | 'timezone' | 'comm_style' | 'onboarding_status' | 'is_fresh_start'>>,
): Promise<User> {
  if (Object.keys(updates).length === 0) throw badRequest('No fields to update');
  const { data, error } = await supabase
    .from('users')
    .update(updates)
    .eq('id', id)
    .select('*')
    .maybeSingle();
  if (error) throw new Error(error.message);
  if (!data) throw notFound('User not found');
  return data as User;
}

export async function getSettings(userId: string): Promise<UserSettings> {
  const { data, error } = await supabase
    .from('user_settings')
    .select('*')
    .eq('user_id', userId)
    .maybeSingle();
  if (error) throw new Error(error.message);
  if (!data) {
    const { data: created, error: insErr } = await supabase
      .from('user_settings')
      .insert({ user_id: userId })
      .select('*')
      .single();
    if (insErr) throw new Error(insErr.message);
    return created as UserSettings;
  }
  return data as UserSettings;
}

export async function updateSettings(
  userId: string,
  updates: Partial<Omit<UserSettings, 'user_id'>>,
): Promise<UserSettings> {
  if (Object.keys(updates).length === 0) throw badRequest('No fields to update');
  await getSettings(userId);
  const { data, error } = await supabase
    .from('user_settings')
    .update(updates)
    .eq('user_id', userId)
    .select('*')
    .single();
  if (error) throw new Error(error.message);
  return data as UserSettings;
}

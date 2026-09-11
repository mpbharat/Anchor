import { supabase } from '../config/supabase';

// push_tokens (canonical): token, platform ios|android|wearos, device_info.
export interface PushToken {
  id: string;
  user_id: string;
  token: string;
  platform: string;
  device_info: string | null;
}

// POST /push-tokens — register a phone/watch (dedupes on token).
export async function registerPushToken(
  userId: string,
  input: { token: string; platform: 'ios' | 'android' | 'wearos'; device_info?: string },
): Promise<PushToken> {
  const { data: existing } = await supabase
    .from('push_tokens')
    .select('id')
    .eq('user_id', userId)
    .eq('token', input.token)
    .maybeSingle();
  const row = {
    user_id: userId,
    token: input.token,
    platform: input.platform,
    device_info: input.device_info ?? null,
  };
  const q = existing
    ? supabase.from('push_tokens').update(row).eq('id', existing.id)
    : supabase.from('push_tokens').insert(row);
  const { data, error } = await q.select('*').single();
  if (error) throw new Error(error.message);
  return data as PushToken;
}

export async function removePushToken(userId: string, token: string): Promise<void> {
  const { error } = await supabase
    .from('push_tokens')
    .delete()
    .eq('user_id', userId)
    .eq('token', token);
  if (error) throw new Error(error.message);
}

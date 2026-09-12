import { supabase } from '../config/supabase';

// integrations (canonical): provider google_calendar|gmail, tokens stored (encrypt
// at rest in production), status connected|revoked. No unique(user_id,provider) in
// the canonical schema, so replace manually per provider.
// 'notifications' is device-local (the Connect screen's third card) — no OAuth,
// just a stored on/off so the app and the nudge scheduler agree.
export type Provider = 'google_calendar' | 'gmail' | 'notifications';

export interface Integration {
  id: string;
  user_id: string;
  provider: string;
  scope: string | null;
  status: string;
  connected_at: string;
}

const PUBLIC = 'id, user_id, provider, scope, status, connected_at';

export async function listIntegrations(userId: string): Promise<Integration[]> {
  const { data, error } = await supabase.from('integrations').select(PUBLIC).eq('user_id', userId);
  if (error) throw new Error(error.message);
  return (data ?? []) as Integration[];
}

// POST /integrations/google — store a read-only Calendar + Gmail grant.
export async function connectGoogle(
  userId: string,
  input: { access_token: string; refresh_token?: string; scope?: string; providers?: Provider[] },
): Promise<Integration[]> {
  const providers = input.providers ?? ['google_calendar', 'gmail'];
  const out: Integration[] = [];
  for (const provider of providers) {
    const row = {
      user_id: userId,
      provider,
      access_token: input.access_token,
      refresh_token: input.refresh_token ?? null,
      scope: input.scope ?? null,
      status: 'connected',
      connected_at: new Date().toISOString(),
    };
    const { data: existing } = await supabase
      .from('integrations')
      .select('id')
      .eq('user_id', userId)
      .eq('provider', provider)
      .maybeSingle();
    const q = existing
      ? supabase.from('integrations').update(row).eq('id', existing.id)
      : supabase.from('integrations').insert(row);
    const { data, error } = await q.select(PUBLIC).single();
    if (error) throw new Error(error.message);
    out.push(data as Integration);
  }
  return out;
}

/// Flips a provider on/off. The first "Connect" for a provider has no row yet,
/// so this inserts rather than failing (the canonical schema has no unique
/// (user_id, provider) index to upsert against).
export async function setStatus(
  userId: string,
  provider: Provider,
  status: 'connected' | 'revoked',
): Promise<Integration> {
  const { data: existing, error: findErr } = await supabase
    .from('integrations')
    .select('id')
    .eq('user_id', userId)
    .eq('provider', provider)
    .maybeSingle();
  if (findErr) throw new Error(findErr.message);

  const query = existing
    ? supabase.from('integrations').update({ status }).eq('id', existing.id)
    : supabase.from('integrations').insert({
        user_id: userId,
        provider,
        status,
        connected_at: new Date().toISOString(),
      });

  const { data, error } = await query.select(PUBLIC).single();
  if (error) throw new Error(error.message);
  return data as Integration;
}

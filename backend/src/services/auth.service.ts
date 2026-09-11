import { supabase, supabaseAuth } from '../config/supabase';
import { badRequest, unauthorized } from '../utils/errors';

export interface Session {
  user: { id: string; email: string };
  access_token: string;
  refresh_token: string;
  expires_at?: number;
}

// Registration goes through Supabase Auth. The DB trigger (handle_new_user)
// creates the public.users profile + default settings. We then patch first_name
// / timezone if supplied.
export async function register(input: {
  email: string;
  password: string;
  first_name?: string;
  timezone?: string;
}): Promise<Session> {
  const { data, error } = await supabaseAuth.auth.signUp({
    email: input.email,
    password: input.password,
  });
  if (error) throw badRequest(error.message);
  if (!data.user) throw badRequest('Sign-up did not return a user');

  const patch: Record<string, string> = {};
  if (input.first_name) patch.first_name = input.first_name;
  if (input.timezone) patch.timezone = input.timezone;
  if (Object.keys(patch).length > 0) {
    // The trigger runs in the same transaction as the auth insert; make sure the
    // profile row exists before patching (upsert covers the race).
    await supabase.from('users').upsert({ id: data.user.id, email: data.user.email, ...patch });
  }

  if (!data.session) {
    // Email confirmation is on for this project — no session is issued yet.
    throw badRequest('Account created. Confirm your email, then log in.');
  }
  return toSession(data.session, data.user);
}

export async function login(email: string, password: string): Promise<Session> {
  const { data, error } = await supabaseAuth.auth.signInWithPassword({ email, password });
  if (error || !data.session || !data.user) {
    throw unauthorized('Invalid email or password');
  }
  return toSession(data.session, data.user);
}

export async function refresh(refreshToken: string): Promise<Session> {
  const { data, error } = await supabaseAuth.auth.refreshSession({ refresh_token: refreshToken });
  if (error || !data.session || !data.user) {
    throw unauthorized('Refresh token is no longer valid');
  }
  return toSession(data.session, data.user);
}

// DEV ONLY: create-or-reset a pre-confirmed user and return a session, so the
// API can be exercised without the email-confirmation step. Uses the secret-key
// admin client. Guarded to development in the controller.
export async function devLogin(email: string, password: string): Promise<Session> {
  const normalized = email.toLowerCase().trim();

  const { error: createErr } = await supabase.auth.admin.createUser({
    email: normalized,
    password,
    email_confirm: true,
  });

  // Already registered → find them and reset password + confirm, so login works.
  if (createErr) {
    const { data: list, error: listErr } = await supabase.auth.admin.listUsers({
      page: 1,
      perPage: 1000,
    });
    if (listErr) throw new Error(listErr.message);
    const existing = list.users.find((u) => u.email?.toLowerCase() === normalized);
    if (!existing) throw badRequest(createErr.message);
    const { error: updErr } = await supabase.auth.admin.updateUserById(existing.id, {
      password,
      email_confirm: true,
    });
    if (updErr) throw new Error(updErr.message);
  }

  return login(normalized, password);
}

export async function logout(accessToken: string): Promise<void> {
  // Revokes the refresh tokens for this session.
  await supabaseAuth.auth.admin?.signOut?.(accessToken).catch(() => undefined);
}

function toSession(
  session: { access_token: string; refresh_token: string; expires_at?: number },
  user: { id: string; email?: string },
): Session {
  return {
    user: { id: user.id, email: user.email ?? '' },
    access_token: session.access_token,
    refresh_token: session.refresh_token,
    expires_at: session.expires_at,
  };
}

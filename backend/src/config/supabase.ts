import { createClient } from '@supabase/supabase-js';
import { env } from './env';

// Secret-key client: full DB access, bypasses RLS. Every request handler uses
// this and scopes queries to the caller's verified user id. Never expose this key
// to the mobile app.
export const supabase = createClient(env.supabaseUrl, env.supabaseSecretKey, {
  auth: { persistSession: false, autoRefreshToken: false },
});

// Publishable-key client: used only to run Supabase Auth email/password flows on
// the user's behalf (register / login). Holds no elevated privileges.
export const supabaseAuth = createClient(env.supabaseUrl, env.supabasePublishableKey, {
  auth: { persistSession: false, autoRefreshToken: false },
});

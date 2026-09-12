import crypto from 'crypto';
import { env } from '../config/env';
import { badRequest } from '../utils/errors';
import { connectGoogle, type Provider } from './integration.service';

// Real Google OAuth for the Connect screen (ANCHOR-BUILD-SPEC.md §7).
//
// Authorization-code flow, exchanged server-side because that is the only way
// to get a refresh_token without shipping the client secret in the app. The
// app's only job is to open the consent URL; it never sees a Google token.
//
// Read-only scopes only. Anchor's promise on the Connect screen is that it
// never sends, deletes, or posts, and the scopes are what actually enforce it.
const SCOPES = [
  'https://www.googleapis.com/auth/calendar.readonly',
  'https://www.googleapis.com/auth/gmail.readonly',
];

const AUTH_ENDPOINT = 'https://accounts.google.com/o/oauth2/v2/auth';
const TOKEN_ENDPOINT = 'https://oauth2.googleapis.com/token';
const STATE_TTL_MS = 10 * 60 * 1000;

function assertConfigured(): void {
  if (!env.googleClientId || !env.googleClientSecret) {
    throw badRequest(
      'Google is not configured: set GOOGLE_CLIENT_ID and GOOGLE_CLIENT_SECRET.',
    );
  }
}

// Google calls the callback with no Authorization header, so the user id has to
// survive the round trip inside `state`. Signed so it cannot be forged and
// time-boxed so a leaked URL goes stale. Keyed on the Supabase secret rather
// than inventing another secret to manage.
function signState(payload: string): string {
  return crypto.createHmac('sha256', env.supabaseSecretKey).update(payload).digest('base64url');
}

export function buildAuthUrl(userId: string): string {
  assertConfigured();

  const payload = Buffer.from(
    JSON.stringify({ uid: userId, exp: Date.now() + STATE_TTL_MS }),
  ).toString('base64url');
  const state = `${payload}.${signState(payload)}`;

  const params = new URLSearchParams({
    client_id: env.googleClientId,
    redirect_uri: env.googleRedirectUri,
    response_type: 'code',
    scope: SCOPES.join(' '),
    // offline + consent is what actually returns a refresh_token. Without it
    // the grant dies in an hour and the nudge scheduler goes quiet.
    access_type: 'offline',
    prompt: 'consent',
    include_granted_scopes: 'true',
    state,
  });

  return `${AUTH_ENDPOINT}?${params.toString()}`;
}

export function verifyState(state: string): string {
  const [payload, signature] = state.split('.');
  if (!payload || !signature) throw badRequest('Malformed OAuth state.');

  const expected = Buffer.from(signState(payload));
  const received = Buffer.from(signature);
  // timingSafeEqual throws when lengths differ, so guard before comparing.
  if (received.length !== expected.length || !crypto.timingSafeEqual(received, expected)) {
    throw badRequest('OAuth state failed verification.');
  }

  let decoded: { uid?: string; exp?: number };
  try {
    decoded = JSON.parse(Buffer.from(payload, 'base64url').toString());
  } catch {
    throw badRequest('Malformed OAuth state.');
  }

  if (!decoded.uid || !decoded.exp) throw badRequest('Malformed OAuth state.');
  if (Date.now() > decoded.exp) throw badRequest('This connect link expired. Try again.');

  return decoded.uid;
}

export async function exchangeCode(
  code: string,
  state: string,
): Promise<{ providers: Provider[] }> {
  assertConfigured();
  const userId = verifyState(state);

  const res = await fetch(TOKEN_ENDPOINT, {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({
      code,
      client_id: env.googleClientId,
      client_secret: env.googleClientSecret,
      redirect_uri: env.googleRedirectUri,
      grant_type: 'authorization_code',
    }),
  });

  if (!res.ok) {
    const body = await res.text();
    throw badRequest(`Google token exchange failed: ${res.status} ${body.slice(0, 300)}`);
  }

  const token = (await res.json()) as {
    access_token: string;
    refresh_token?: string;
    scope?: string;
  };

  // The consent screen lets people untick an individual scope, so trust what
  // Google says was granted rather than what we asked for.
  const granted = token.scope ?? '';
  const providers: Provider[] = [];
  if (granted.includes('calendar.readonly')) providers.push('google_calendar');
  if (granted.includes('gmail.readonly')) providers.push('gmail');
  if (providers.length === 0) throw badRequest('No read-only Google scopes were granted.');

  await connectGoogle(userId, {
    access_token: token.access_token,
    refresh_token: token.refresh_token,
    scope: token.scope,
    providers,
  });

  return { providers };
}

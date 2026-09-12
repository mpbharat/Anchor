// OpenAPI 3.0 document for the Anchor API, served at /openapi.json and rendered
// by Swagger UI at /docs. Paths mirror ANCHOR-BUILD-SPEC.md §7 (served at root).
//
// To try authed routes in /docs: POST /auth/dev-login (no auth needed) → copy
// access_token → click "Authorize" → paste it → run any endpoint.

const bearer = [{ bearerAuth: [] as string[] }];
const jsonBody = (example: Record<string, unknown>) => ({
  required: true,
  content: { 'application/json': { schema: { type: 'object' }, example } },
});
const ok = (description: string) => ({ description });
const idParam = {
  name: 'id',
  in: 'path',
  required: true,
  schema: { type: 'string', format: 'uuid' },
};

export const openapiSpec = {
  openapi: '3.0.3',
  info: {
    title: 'Anchor API',
    version: '0.1.0',
    description:
      'Backend for the Anchor app (V2 Duo). All routes except /health and /auth/* require a Supabase Bearer token.\n\n' +
      '**Quick start:** run `POST /auth/dev-login` (no auth), copy the `access_token`, click **Authorize** above, paste it, then try any endpoint.',
  },
  servers: [{ url: '/', description: 'this server' }],
  tags: [
    { name: 'Auth' },
    { name: 'Profile & settings' },
    { name: 'Weeks & commitments' },
    { name: 'AI (judge, silence, messages)' },
    { name: 'Import & integrations' },
    { name: 'Nudges & delivery' },
    { name: 'Witness' },
    { name: 'Companion' },
    { name: 'Health' },
  ],
  components: {
    securitySchemes: {
      bearerAuth: { type: 'http', scheme: 'bearer', bearerFormat: 'JWT' },
    },
  },
  security: bearer, // default; individual public routes override with security: []
  paths: {
    '/health': {
      get: { tags: ['Health'], summary: 'Liveness check', security: [], responses: { 200: ok('OK') } },
    },

    // ---- Auth (public) ----
    '/auth/register': {
      post: {
        tags: ['Auth'], summary: 'Register (Supabase Auth)', security: [],
        requestBody: jsonBody({ email: 'you@example.com', password: 'password123', first_name: 'Merlin', timezone: 'Asia/Dubai' }),
        responses: { 201: ok('Session (or confirm-email message)'), 400: ok('Bad request') },
      },
    },
    '/auth/login': {
      post: {
        tags: ['Auth'], summary: 'Log in', security: [],
        requestBody: jsonBody({ email: 'you@example.com', password: 'password123' }),
        responses: { 200: ok('{ user, access_token, refresh_token, expires_at }'), 401: ok('Invalid credentials') },
      },
    },
    '/auth/refresh': {
      post: {
        tags: ['Auth'], summary: 'Refresh session', security: [],
        requestBody: jsonBody({ refresh_token: '<refresh_token>' }),
        responses: { 200: ok('New session'), 401: ok('Invalid refresh token') },
      },
    },
    '/auth/dev-login': {
      post: {
        tags: ['Auth'],
        summary: 'DEV ONLY — pre-confirmed session (no email step)',
        description: 'Creates/resets a confirmed user and returns a session. 404 outside development. Body optional; defaults to dev@anchor.test.',
        security: [],
        requestBody: { required: false, content: { 'application/json': { schema: { type: 'object' }, example: { email: 'dev@anchor.test', password: 'anchor-dev-password' } } } },
        responses: { 200: ok('Session'), 404: ok('Not in development') },
      },
    },
    '/auth/logout': {
      post: { tags: ['Auth'], summary: 'Log out (revoke session)', responses: { 204: ok('No content') } },
    },

    // ---- Profile & settings ----
    '/me': {
      get: { tags: ['Profile & settings'], summary: 'Profile + settings', responses: { 200: ok('{ user, settings }') } },
      patch: {
        tags: ['Profile & settings'], summary: 'Update profile',
        requestBody: jsonBody({ first_name: 'Merlin', timezone: 'Asia/Dubai', comm_style: 'direct', onboarding_status: 'active', is_fresh_start: false }),
        responses: { 200: ok('{ user }') },
      },
    },
    '/settings': {
      get: { tags: ['Profile & settings'], summary: 'Get settings', responses: { 200: ok('{ settings }') } },
      put: {
        tags: ['Profile & settings'], summary: 'Update settings',
        requestBody: jsonBody({ review_day: 'fri', review_time: '21:00', nudge_style: 'only_matters', quiet_hours: {}, cap: 4 }),
        responses: { 200: ok('{ settings }') },
      },
    },

    // ---- Weeks & commitments ----
    '/weeks/current': {
      post: { tags: ['Weeks & commitments'], summary: 'Start/fetch this week', responses: { 200: ok('{ week }') } },
    },
    '/weeks/current/commitments': {
      get: { tags: ['Weeks & commitments'], summary: 'The Load (four with status + progress)', responses: { 200: ok('{ week, cap, loaded, commitments }') } },
    },
    '/weeks/{id}/review': {
      get: { tags: ['Weeks & commitments'], summary: 'End-of-week standing', parameters: [idParam], responses: { 200: ok('{ week, kept_count, total_count, anchor_message, commitments }') } },
    },
    '/weeks/{id}/close': {
      post: {
        tags: ['Weeks & commitments'], summary: 'Close week + roll into next', parameters: [idParam],
        requestBody: jsonBody({ mode: 'same', carry_commitment_ids: [] }),
        responses: { 201: ok('{ closed, next, commitments }') },
      },
    },
    '/commitments': {
      post: {
        tags: ['Weeks & commitments'], summary: 'Add one of the four (5th → the "no")',
        requestBody: jsonBody({ title: 'Three gym sessions', kind: 'recurring', metric: 'count', target_value: 3, unit: 'times', period: 'week', wish: 'Feel strong', obstacle: 'Late meetings', if_trigger: 'If a 6pm meeting runs over', then_action: 'go at 7am instead' }),
        responses: { 201: ok('{ decision: "added", commitment }'), 409: ok('{ decision: "no", message, loaded, cap, commitments }') },
      },
    },
    '/commitments/{id}': {
      get: { tags: ['Weeks & commitments'], summary: 'Get a commitment + intention', parameters: [idParam], responses: { 200: ok('{ commitment }') } },
      patch: {
        tags: ['Weeks & commitments'], summary: 'Edit commitment / intention', parameters: [idParam],
        requestBody: jsonBody({ title: 'Two gym sessions', target_value: 2 }),
        responses: { 200: ok('{ commitment }') },
      },
      delete: { tags: ['Weeks & commitments'], summary: 'Drop (frees the cap)', parameters: [idParam], responses: { 200: ok('{ commitment }') } },
    },
    '/commitments/{id}/checkin': {
      put: {
        tags: ['Weeks & commitments'], summary: 'Tick progress / done / miss', parameters: [idParam],
        requestBody: jsonBody({ kind: 'progress', value: 1, note: 'morning session' }),
        responses: { 200: ok('{ commitment }') },
      },
    },
    '/commitments/{id}/swap': {
      post: {
        tags: ['Weeks & commitments'], summary: 'Swap one out for a new one', parameters: [idParam],
        requestBody: jsonBody({ replacement: { title: 'Call Dad, Sunday', kind: 'oneoff', metric: 'boolean' } }),
        responses: { 201: ok('{ swapped_out, swapped_in }') },
      },
    },

    // ---- AI ----
    '/judge': {
      post: {
        tags: ['AI (judge, silence, messages)'],
        summary: 'Judge a request/signal → nudge | stay_silent | declined | …',
        description: 'Records a judgment. Pass the AI verdict/spoken, or send a budget signal (commitment_id + amount) for the deterministic breach check. verdict=nudge also schedules a nudge.',
        requestBody: jsonBody({ source: 'voice', request: 'add a newsletter', verdict: 'declined', spoken: "You're at four and behind on the gym — if it goes in, which comes out?", reasoning: 'at cap', weighed_against: ['Gym', 'Dad'], suggested_action: null }),
        responses: { 201: ok('{ verdict, spoken, reasoning, weighed_against, suggested_action, nudge }') },
      },
    },
    '/silence-log': {
      get: { tags: ['AI (judge, silence, messages)'], summary: 'Everything Anchor chose not to say', responses: { 200: ok('{ judgments }') } },
    },
    '/judgments': {
      get: { tags: ['AI (judge, silence, messages)'], summary: 'Full judgment log', responses: { 200: ok('{ judgments }') } },
    },
    '/messages': {
      get: { tags: ['AI (judge, silence, messages)'], summary: 'Conversation log', responses: { 200: ok('{ messages }') } },
      post: {
        tags: ['AI (judge, silence, messages)'], summary: 'Append a turn (+ optional Anchor reply)',
        requestBody: jsonBody({ role: 'user', content: 'Add gym three times', turn_kind: 'commit', reply: { content: 'Done — that is three of four.', turn_kind: 'commit' } }),
        responses: { 201: ok('{ message, reply }') },
      },
    },

    // ---- Import & integrations ----
    '/users/{id}/patterns': {
      post: {
        tags: ['Import & integrations'], summary: 'Bring your history (id may be "me")',
        parameters: [idParam],
        requestBody: jsonBody({ source: 'chatgpt', personality: { risk: 'overcommits' }, pitfalls: ['says yes then resents it'], working_style: 'deep-work mornings', current_projects: ['Anchor'], baseline_load: 'near capacity', priorities: ['ship > polish'], habits: ['orders food ~Sat 6pm'], raw_import: '<pasted text>' }),
        responses: { 201: ok('{ patterns }') },
      },
      get: { tags: ['Import & integrations'], summary: 'What Anchor learned', parameters: [idParam], responses: { 200: ok('{ patterns }') } },
      delete: { tags: ['Import & integrations'], summary: 'Fresh start (clear history)', parameters: [idParam], responses: { 204: ok('No content') } },
    },
    '/users/{id}/load': {
      get: { tags: ['Import & integrations'], summary: 'Current load + spend totals', parameters: [idParam], responses: { 200: ok('{ commitments, spend_by_category, event_count }') } },
    },
    '/integrations': {
      get: { tags: ['Import & integrations'], summary: 'Connected providers', responses: { 200: ok('{ integrations }') } },
    },
    '/integrations/google': {
      post: {
        tags: ['Import & integrations'], summary: 'Store read-only Calendar + Gmail grant',
        requestBody: jsonBody({ access_token: 'ya29.…', refresh_token: '1//…', scope: 'calendar.readonly gmail.readonly', providers: ['google_calendar', 'gmail'] }),
        responses: { 201: ok('{ integrations }') },
      },
    },
    '/integrations/status': {
      put: {
        tags: ['Import & integrations'], summary: 'Set a provider connected/revoked',
        requestBody: jsonBody({ provider: 'gmail', status: 'revoked' }),
        responses: { 200: ok('{ integration }') },
      },
    },
    '/signals': {
      post: {
        tags: ['Import & integrations'], summary: 'Push a parsed purchase / event / ask',
        requestBody: jsonBody({ source: 'gmail', kind: 'purchase', merchant: 'Amazon', amount: 350, category: 'shopping', title: 'Order confirmation' }),
        responses: { 201: ok('{ signal }') },
      },
      get: { tags: ['Import & integrations'], summary: 'Recent signals', responses: { 200: ok('{ signals }') } },
    },

    // ---- Nudges & delivery ----
    '/nudges': {
      post: {
        tags: ['Nudges & delivery'], summary: 'Schedule a nudge',
        requestBody: jsonBody({ body: 'Gym at 6?', channel: 'push', fire_at: '2026-09-12T14:00:00Z' }),
        responses: { 201: ok('{ nudge }') },
      },
      get: { tags: ['Nudges & delivery'], summary: 'Scheduled nudges (?all=true for sent/acted)', responses: { 200: ok('{ nudges }') } },
    },
    '/nudges/{id}/respond': {
      put: {
        tags: ['Nudges & delivery'], summary: 'On it / Snooze', parameters: [idParam],
        requestBody: jsonBody({ action: 'on_it', snooze_minutes: 30 }),
        responses: { 200: ok('{ nudge }') },
      },
    },
    '/push-tokens': {
      post: {
        tags: ['Nudges & delivery'], summary: 'Register a device token',
        requestBody: jsonBody({ token: 'fcm-token', platform: 'ios', device_info: 'iPhone 15' }),
        responses: { 201: ok('{ push_token }') },
      },
      delete: {
        tags: ['Nudges & delivery'], summary: 'Remove a device token',
        requestBody: jsonBody({ token: 'fcm-token' }),
        responses: { 204: ok('No content') },
      },
    },

    // ---- Witness ----
    '/witnesses': {
      get: { tags: ['Witness'], summary: 'List witnesses', responses: { 200: ok('{ witnesses }') } },
      post: {
        tags: ['Witness'], summary: 'Add the one optional witness',
        requestBody: jsonBody({ name: 'Sam', contact: '+971…', channel: 'whatsapp' }),
        responses: { 201: ok('{ witness }') },
      },
    },
    '/witnesses/{id}': {
      delete: { tags: ['Witness'], summary: 'Remove a witness', parameters: [idParam], responses: { 204: ok('No content') } },
    },

    // ---- Companion ----
    '/companion/web-search': {
      post: {
        tags: ['Companion'], summary: 'Grounded web search (Exa)',
        description: 'Requires EXA_API_KEY in the environment.',
        requestBody: jsonBody({ query: 'evidence for implementation intentions', numResults: 5 }),
        responses: { 200: ok('{ results }') },
      },
    },
  },
} as const;

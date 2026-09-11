# backend/ — API endpoints & nudge scheduler (owner: Merlin)

The API everyone else calls, plus the job that fires nudges.

**Choice: a small Node service** (Express + TypeScript), not Edge Functions — one process, easy local run, standard middleware. Lives in `backend/src`; the nudge scheduler will be a cron-driven entry point reusing the same services (`nudge.service.listDue`).

## Run it

```bash
cd backend
cp .env.example .env      # fill Supabase keys (or put them in the repo-root .env)
npm install
npm run dev               # http://localhost:3000, hot-reload via tsx
```

Auth is via Supabase; every route is scoped to the signed-in user (`Authorization: Bearer <supabase access_token>`). Routes are served at root, matching §7 exactly (`POST /weeks/current`, `POST /judge`, …). Convenience auth proxies live under `/auth` (`/auth/login`, `/auth/register`, and a dev-only `/auth/dev-login` that returns a pre-confirmed session for local testing). Layout: `src/{config,middleware,routes,controllers,services,utils}`.

Schema of record is [`supabase/migrations/0001_init.sql`](../supabase/migrations/0001_init.sql); the service is written to those exact columns.

## The API contract (the seam — agree the shapes)
Full list + example payloads in `ANCHOR-BUILD-SPEC.md §7`. Summary:

**Onboarding & commitments**
- `POST /weeks/current` · `POST /commitments` (rejects a 5th → returns the "no") · `GET /weeks/current/commitments` · `PUT /commitments/:id/checkin` · `GET /weeks/:id/review`

**The AI (Bharat)**
- `POST /judge` → `{verdict, reasoning, weighed_against, suggested_action}` · `GET /silence-log` · `POST /messages`

**Import & integrations (Maria calls)**
- `POST /users/:id/patterns` · `POST /integrations/google` · `POST /signals` · `GET /users/:id/load`

**Nudges & delivery**
- `POST /nudges` · `PUT /nudges/:id/respond` · `POST /push-tokens`

## Today vs event day
- **Today (body):** every route stubbed, returning mock data in the documented shape. This unblocks Bharat (front-end) and Maria (integrations) immediately.
- **Event day (net-new):** cap enforcement, weekly-review rollups, and the **nudge scheduler** — an Edge Function on a cron (~every 5 min) that reads due `nudges`, re-checks (skip if already handled), and delivers via FCM. Log each send to keep an audit trail.

## Learned from Zaasu (see spec §8.6)
- Code decides *when* to fire; the LLM only proposes a schedule offline.
- Dedupe on the user's **local** day, not UTC. Pass explicit timezones to cron.
- Give every nudge a specific commitment + a next physical action.

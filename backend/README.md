# backend/ — API endpoints & nudge scheduler (owner: Merlin)

The API everyone else calls, plus the job that fires nudges. Supabase Edge Functions (or a small Node service — pick one and note it here).

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

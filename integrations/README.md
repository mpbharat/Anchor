# integrations/ — import extraction & Google (owner: Maria)

Two jobs: (1) extract "bring your history" details from a ChatGPT/Claude paste or uploaded file, (2) read-only Gmail + Google Calendar.

**You call Merlin's API endpoints — you never touch the database directly.** The schema (`ANCHOR-BUILD-SPEC.md §6`) is there only so you know the shapes.

## 1. Import extraction
Anchor shows the user a prompt to run in ChatGPT/Claude; they paste the reply (or upload `.md`/`.json`). You extract it into the shape below and `POST /users/:id/patterns`. See `example-patterns.json`.

## 2. Gmail + Calendar (read-only)
- Store the grant via `POST /integrations/google` (read-only scopes only — Anchor never sends, deletes, or posts).
- Send only selected load signals: purchases, actionable incoming asks, and upcoming non-cancelled regular events. Gmail fetches metadata only and excludes promotional, social, forum, spam, newsletter, and ordinary correspondence.
- `POST /signals` is authenticated. Set `ANCHOR_API_TOKEN` to the signed-in user's Supabase access token before calling `sync_relevant_emails()` or `sync_relevant_events()`; never commit it.
- Signals default to `https://anchor-qo9j.onrender.com/signals`. To use a local backend instead, set `ANCHOR_SIGNALS_API_URL=http://localhost:3000/signals` in your shell.
- Parse purchases / events / incoming asks and push them via `POST /signals` → they land in `load_signals` and feed the nudge engine.
- **One shared Google account is enough for the demo.** Do not build per-user OAuth — it's a config swap later, not a rebuild.

## Today vs event day
- **Today (body):** OAuth app registered, read-only connect working on our account; produce parsed *test* payloads that match the shapes.
- **Event day (net-new):** live extraction → `/users/:id/patterns`, and a real Amazon-style email → `/signals` → a real nudge.

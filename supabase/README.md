# supabase/ — database & config (owner: Merlin)

Postgres schema, migrations, and Edge Functions config.

## What's here
- `migrations/0001_init.sql` — the full schema (16 tables). Multi-user; empty tables are scaffolding, not product logic.

## Run locally
```bash
supabase start          # local stack
supabase db reset       # applies everything in migrations/
```

## Schema at a glance
`ANCHOR-BUILD-SPEC.md §6` has the annotated version. Core product tables: `users`, `user_settings`, `user_patterns`, `weeks`, `commitments`, `intentions`, `check_ins`, `judgments`, `weekly_reviews`, `patterns`, `messages`, `witnesses`. Integration/delivery: `integrations`, `load_signals`, `nudges`, `push_tokens`.

Key ideas:
- **`judgments`** logs every AI decision including `verdict='stay_silent'` — that IS the silence log.
- **`commitments`** generalises to boolean / count / amount so "call Dad", "3 gym", and "under 1k AED/month" all fit.
- **`patterns`** holds learned behaviours that fire proactive nudges.

## Today vs event day
- **Today (body):** tables exist and are empty; endpoint stubs read/write mock data.
- **Event day (net-new):** cap enforcement on write, weekly-review rollups, the nudge scheduler Edge Function, and **RLS policies on every table**.

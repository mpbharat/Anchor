-- Anchor — initial schema (the "body"; empty tables are scaffolding, not product logic)
-- Multi-user from day one. Everything hangs off users.id. RLS should scope every row to the signed-in user.
-- Patterned on Zaasu: jsonb where a rigid column would slow us down; a judgments log that also captures silence.

-- ---------- core: the product ----------

create table if not exists users (
  id uuid primary key references auth.users(id),
  email text,
  first_name text,
  timezone text default 'Asia/Dubai',
  comm_style text,
  onboarding_status text default 'new',
  is_fresh_start boolean default false,
  created_at timestamptz default now()
);

create table if not exists user_settings (
  user_id uuid primary key references users(id) on delete cascade,
  review_day text default 'fri',
  review_time time default '21:00',
  nudge_style text default 'only_matters',   -- only_matters | quiet | off
  quiet_hours jsonb,
  cap int default 4
);

-- output of the "bring your history" import (Maria POSTs this shape via the API)
create table if not exists user_patterns (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references users(id) on delete cascade,
  personality jsonb,
  pitfalls jsonb,
  working_style text,
  current_projects jsonb,
  baseline_load text,
  priorities jsonb,
  habits jsonb,
  source text,              -- chatgpt | claude | upload | fresh
  raw_import text,
  extracted_at timestamptz default now()
);

create table if not exists weeks (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references users(id) on delete cascade,
  week_start date,
  week_number int,
  status text default 'active'
);

create table if not exists commitments (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references users(id) on delete cascade,
  week_id uuid references weeks(id) on delete cascade,
  title text,
  kind text,                -- oneoff | recurring | budget
  metric text,              -- boolean | count | amount
  target_value numeric,
  unit text,                -- times | AED | null
  period text,              -- week | month
  current_value numeric default 0,
  position int,             -- 1..4 (cap enforced on write)
  status text default 'on_record', -- on_record | due | done | carried | dropped
  carried_from uuid,
  completed_at timestamptz
);

-- the WOOP / if-then per commitment
create table if not exists intentions (
  id uuid primary key default gen_random_uuid(),
  commitment_id uuid references commitments(id) on delete cascade,
  wish text,
  obstacle text,
  if_trigger text,
  then_action text
);

-- progress: "1 of 3 gym"; rolls up into commitments.current_value
create table if not exists check_ins (
  id uuid primary key default gen_random_uuid(),
  commitment_id uuid references commitments(id) on delete cascade,
  occurred_at timestamptz default now(),
  kind text,                -- progress | done | miss
  value numeric,
  note text
);

-- every AI judgment, INCLUDING the silent ones (silence log = verdict='stay_silent')
create table if not exists judgments (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references users(id) on delete cascade,
  week_id uuid references weeks(id) on delete set null,
  trigger text,
  source text,              -- voice | email | pattern | calendar
  verdict text,             -- nudge | stay_silent | declined | allowed | swapped
  reasoning text,
  weighed_against jsonb,
  overridden boolean default false,
  created_at timestamptz default now()
);

create table if not exists weekly_reviews (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references users(id) on delete cascade,
  week_id uuid references weeks(id) on delete cascade,
  kept_count int,
  total_count int,
  anchor_message text,
  created_at timestamptz default now()
);

-- learned behaviours that fire PROACTIVE nudges (e.g. "orders food Sat ~18:00")
create table if not exists patterns (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references users(id) on delete cascade,
  commitment_id uuid references commitments(id) on delete set null,
  kind text,                -- spend | recurring_time | place
  descriptor text,
  schedule text,            -- e.g. "Sat ~18:00"
  confidence numeric,
  last_seen timestamptz,
  source text               -- observed | imported
);

-- voice conversation memory (AI context / continuity)
create table if not exists messages (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references users(id) on delete cascade,
  role text,                -- user | anchor
  content text,
  turn_kind text,           -- commit | decline | checkin | chat
  created_at timestamptz default now()
);

-- optional human accountability loop
create table if not exists witnesses (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references users(id) on delete cascade,
  name text,
  contact text,
  channel text,             -- email | whatsapp
  status text default 'invited'
);

-- ---------- integrations & delivery ----------

-- read-only Google grants (Maria connects; Merlin owns the table)
create table if not exists integrations (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references users(id) on delete cascade,
  provider text,            -- google_calendar | gmail
  access_token text,        -- store encrypted
  refresh_token text,       -- store encrypted
  scope text,
  status text default 'connected', -- connected | revoked
  connected_at timestamptz default now()
);

-- parsed reads of calendar/mail incl. purchases, so the AI can weigh real load + spend
create table if not exists load_signals (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references users(id) on delete cascade,
  source text,              -- calendar | gmail
  kind text,                -- event | ask | purchase
  title text,
  merchant text,
  amount numeric,
  category text,
  occurred_at timestamptz
);

create table if not exists nudges (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references users(id) on delete cascade,
  commitment_id uuid references commitments(id) on delete set null,
  fire_at timestamptz,
  channel text,             -- push | watch
  title text,
  body text,
  status text default 'scheduled', -- scheduled | sent | acted | snoozed
  sent_at timestamptz
);

create table if not exists push_tokens (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references users(id) on delete cascade,
  token text,
  platform text,            -- ios | android | wearos
  device_info text
);

-- TODO (event day): enable RLS + per-user policies on every table before real users.

# Anchor

**The commitment agent that says no.** Anchor is a phone app (iOS + Android) with a voice agent that makes you commit to only **3–4 things a week** and pushes back when you try to take on more. It is silent by default — its core skill is deciding *when it has earned the right to interrupt you* — but always one tap away when you want to talk.

> Anchor holds you to a few things and says no to the rest. It costs you seconds a day, not your attention.

Built for the agent hackathon (Team "The Crawlers"). Powered by OpenAI — the user never sees a provider or model name.

---

## What makes it different

- **Silent by default, always available.** It never barges into your day uninvited (an interruption must be *earned*), but the moment you reach for it, it's there with full context — coach, counsellor, or friend, with accountability underneath.
- **Enforced scarcity.** A hard cap of ~4 commitments a week. Backed by WIP limits and the planning fallacy, not a magic number.
- **The silence log.** Everything Anchor chose *not* to say. A chatbot can't choose silence or timing — this is the differentiator.
- **Grounded in you.** Optional import of your ChatGPT / Claude history so it knows your pitfalls and load from minute one.

Full product spec, screens, flows, schema, nudge logic, API contract and the two-day plan are in **[`ANCHOR-BUILD-SPEC.md`](./ANCHOR-BUILD-SPEC.md)** and the design artifact (link in the team chat).

---

## Repository layout (by owner)

```
Anchor/
├── ANCHOR-BUILD-SPEC.md   The single source of truth. Read this first.
├── app/            Flutter app — iOS + Android          → Bharat (front-end)
├── ai/             The brain: judgment + nudge logic     → Bharat (AI)
├── backend/        API endpoints + nudge scheduler       → Merlin
├── supabase/       Database schema (migrations) + config → Merlin
├── integrations/   ChatGPT/Claude import + Gmail/Calendar → Maria
└── docs/           Design notes, links
```

Each folder has its own README with what's scaffolded now vs. what's built on event day.

---

## The two-day rule (hackathon eligibility)

The project's **core functionality must be net-new during the event**; templates, scaffolding, libraries and starter code are explicitly allowed.

- **Today (the body — legal scaffolding):** repo, schema, screens as static UI, endpoint stubs, integrations boilerplate, deploy. **No commitment/judgment/nudge logic.**
- **Event day (the brain — net-new):** the judgment engine (the "no"), the nudge engine (reactive + proactive), cap enforcement, the silence log, weekly review, live import, wiring screens to real data.

Keep this line visible. Do not build product logic before the event.

---

## Stack

- **App:** Flutter (Dart) — one codebase → iOS + Android (web later if wanted).
- **Backend / DB / Auth:** Supabase (Postgres + Auth + Edge Functions). RLS on; every row scoped to the signed-in user.
- **AI:** OpenAI via the sponsor key, behind env vars (`OPENAI_BASE_URL`, `OPENAI_MODEL`) so it's swappable. Provider/model never surfaced to the user.
- **Nudges:** an Edge Function on a cron reads due nudges and delivers via FCM.

---

## Getting started

```bash
# 1. Clone
git clone https://github.com/mpbharat/Anchor.git && cd Anchor

# 2. App (Flutter)
cd app && flutter pub get && flutter run

# 3. Backend / DB (Supabase)
cd supabase && supabase start        # local stack
supabase db reset                    # applies migrations/

# 4. Secrets (never commit)
cp .env.example .env                 # fill OPENAI_API_KEY, SUPABASE_URL, etc.
```

See each folder's README for details. Secrets live in `.env` (gitignored) — never commit keys.

---

## Team

| Owner | Area | Folders |
|-------|------|---------|
| **Bharat** | The AI + the full front-end | `app/`, `ai/` |
| **Merlin** | Backend, API endpoints, Supabase | `backend/`, `supabase/` |
| **Maria** | Import extraction + Gmail/Calendar | `integrations/` |

The **API contract** in `ANCHOR-BUILD-SPEC.md §7` is the seam between everyone — agree the shapes, build behind them.

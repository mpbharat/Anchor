# Anchor

**The agent that says no.**

Anchor is a commitment and accountability agent that lives on your phone (iOS + Android). Every productivity tool helps you add more. Anchor does the opposite: it holds you to three or four things a week, learns how you overcommit, and pushes back the moment you try to take on a fifth. Saying no is the feature.

Built at the **Agents Everywhere** hackathon by Team **The Crawlers**.

### Live
- **Website:** https://anchor-4zt.pages.dev
- **How it works (deep dive):** https://anchor-4zt.pages.dev/how-it-works.html
- **Try the app in your browser:** https://anchor-4zt.pages.dev/app/
- **API:** https://anchor-qo9j.onrender.com (docs at `/docs`)
- **Demo video:** _(2-min, added before submission)_

---

## The problem

People do not fail their goals because they lack tools to add tasks. They fail because they take on too much, then resent it, then drop everything. Anchor is the first agent whose job is to protect your capacity, not fill it. It lives where you actually overcommit (your phone, your calendar, your inbox), so it can push back in the moment, the way a standalone chatbot never could.

## What Anchor does

- **A hard cap of four.** You put three or four commitments on the record for the week. That limit is the point. Anchor guards it.
- **It says no.** Try to add a fifth and Anchor refuses, in a Motivational-Interviewing style: it reflects your ask back, affirms it is your call, names exactly what it weighed against, and offers the trade. It uses your real numbers and never invents them.
- **It learns you.** After every conversation, a reflection pass updates its durable memory of your pitfalls, priorities, and habits. The more you talk, the sharper its push-back.
- **It talks, out loud.** A live, duplex voice conversation (OpenAI Realtime). Think out loud and it answers in the moment, grounding factual questions in real sources via Exa instead of guessing.
- **It nudges, reactively and proactively.** Reactive when a signal breaches a commitment now (an Amazon receipt over your dining budget, a meeting on your deep-work morning). Proactive when it sees a pattern coming (Friday takeaway, Monday over-loading). On your phone and your wrist.
- **It stays silent.** When there is nothing worth saying, it says nothing, and logs every silent call. The silence log is the opposite of an app fighting for your attention.
- **It settles up, kindly.** A weekly recap of what you kept and what slipped. A miss is named plainly, then forgiven and carried, never turned into a shame spiral.
- **It knows you from day one.** Optional import of a ChatGPT or Claude export, plus read-only Google Calendar + Gmail, so it sees your real load.

## How it works

Anchor runs one loop every week: **you commit → it watches your real life → it pushes back or nudges → it settles up on Friday**, then resets.

The intelligence behind it:

- **Judgment engine** (`backend/src/services/brain.service.ts`) reasons over your live load and profile with OpenAI and returns the verdict (declined / allowed / swapped), the spoken line, and the weighed-against list. Every judgment, including the silent ones, is written to the `judgments` table.
- **Conversational companion** (`companion.service.ts`) is one voice that flexes across coach, counsellor, friend, and accountability partner. It grounds facts mid-conversation with an Exa web-search tool (OpenAI function calling).
- **Memory reflection** (`memory.service.ts`) is a debounced pass that turns conversation into durable `user_patterns`. The model proposes, the code reconciles and dedupes, so memory sharpens instead of bloating. (Design informed by studying a production agent's engines and fixing their defects: real upsert, capped merge, timestamps stamped in code, no per-message cost.)
- **Live voice** uses OpenAI Realtime over WebRTC. The backend mints a short-lived key seeded with the persona + load; the app streams audio both ways. The OpenAI key never reaches the client.

## Based on the science

Every behaviour traces to a finding: implementation intentions (Gollwitzer), WIP limits and Little's Law, Motivational Interviewing and reactance (Miller & Rollnick; Brehm), the planning fallacy (Kahneman & Tversky), self-forgiveness and the what-the-hell effect (Polivy & Herman; Wohl), the fresh-start effect (Milkman), and overjustification (Deci) — which is why Anchor has no points, streaks, or gamification. The only reward is keeping your word.

## Screens

- **Talk** — the home. Conversation with Anchor by text or live voice; a Profile button (import + connectors) and a + to commit.
- **Focus** — the few things you are holding this week. Tap one to expand for inline progress, or open a Pulse-style detail with status, cadence, a progress bar, and a full check-in log.
- **Recap** — the weekly review: what you kept, what slipped, forgiven and carried.
- **Profile** — import your ChatGPT/Claude history, connect Google (read-only), privacy.

## Tech & architecture

| Layer | Tech |
|---|---|
| App | Flutter (Dart), one codebase for iOS + Android; `flutter_webrtc` for live voice |
| Backend | Node + Express + TypeScript |
| Data + Auth | Supabase (Postgres, Auth, RLS), 16-table schema |
| AI | OpenAI (judgment, companion, memory), OpenAI Realtime (voice) |
| Grounding | Exa (semantic web search) |
| Voice models | OpenRouter |
| Integrations | Google Calendar + Gmail (read-only) |
| Hosting | Cloudflare Pages (site + web app), Render (API), Supabase (data) |

### Repository layout (by owner)

```
Anchor/
├── app/            Flutter app: screens, AI wiring, live voice   (Bharat)
├── backend/        Express + TS API: judgment, companion,        (Merlin + Bharat)
│                   memory, realtime, nudges
├── supabase/       Postgres schema + migrations                  (Merlin)
├── integrations/   ChatGPT/Claude import + Gmail/Calendar         (Mary)
├── site/           Marketing site + how-it-works (Cloudflare)     (Bharat)
├── docs/           Submission, hosting, notes
└── ANCHOR-BUILD-SPEC.md   Product + technical source of truth
```

## Run it locally

```bash
# Backend
cd backend
cp ../.env.example .env          # fill in OPENAI / SUPABASE / EXA / OPENROUTER keys
npm install && npm run dev       # http://localhost:3000  (GET /health)

# App (iOS simulator or Android)
cd app
flutter pub get
flutter run                      # talks to the local backend

# Web build (what the site embeds)
flutter build web --base-href "/app/" --release
```

Environment variables are documented in [`.env.example`](./.env.example). Hosting/deploy steps are in [`docs/HOSTING.md`](./docs/HOSTING.md).

## Team

| Person | Role |
|---|---|
| **Bharat Sankar** | Lead: product, design, the AI brain (judgment, memory, live voice), the Flutter app, the website |
| **Mary Sophiya** | Import from ChatGPT/Claude, Google Calendar + Gmail integration |
| **Merlin Jose** | Supabase schema, the Node + TypeScript API, integrations backend, Android + CI |

## Prior work

Before the event we created the concept, the design system and mockups, a written spec, and a scaffolded monorepo (schema, API stubs on mock data, a static front end). During the hackathon we built the intelligence: the judgment engine, the conversational companion, the memory reflection pass, Exa grounding, the OpenAI Realtime voice loop, the live import + Google integration, and wired every screen to real data.

---

_#AgentsEverywhere · The Crawlers_

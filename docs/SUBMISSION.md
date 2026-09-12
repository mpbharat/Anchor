# Anchor — Submission (Team: The Crawlers)

Deadline: today 4:30 PM +04. Everything below is final and paste-ready.

## Project Name
**Anchor**

## Project Description (paste this)

Anchor is a commitment and accountability agent that lives inside your phone, the place where you already plan your week, get pinged, and overcommit. Most productivity tools help you add more. Anchor does the opposite: it holds you to three or four things a week and pushes back when you try to take on a fifth. That refusal is the product.

The environment is the point. Because Anchor lives on the device with your notifications, calendar, and mail, it sees your real load, not a self-report. When a purchase email or a new calendar invite would push you past your limit, Anchor speaks up in the moment; when nothing needs saying, it stays silent, and every silent judgment is logged so you can see everything it chose not to interrupt you with. A standalone chatbot cannot do this: it has no presence in the context where commitments are made and broken.

You talk to Anchor by voice, a live duplex conversation like a coach who knows your week. It reasons over your live commitments with OpenAI, applies behavioral science (implementation intentions, work-in-progress limits, self-forgiveness on a miss instead of shame), learns your patterns after every conversation, and grounds its push-back in real sources through Exa web search, so when it says a deadline is unrealistic it can show you why. The voice layer runs on OpenAI Realtime and OpenRouter.

Technical execution: a Flutter app (one codebase for iOS and Android) on a Supabase backend (Postgres, Auth, RLS) with a Node and TypeScript API. OpenAI drives judgment, memory, and the companion; OpenAI Realtime over WebRTC powers live voice; Exa grounds the coaching; Google Calendar and Gmail feed read-only load signals. The result is an agent that protects your attention instead of competing for it.

## Products & Tools Used (tick these)
- [x] AI Tinkerers
- [x] OpenAI
- [x] OpenRouter
- [x] Exa

**Other Products:** Supabase (Postgres, Auth), Flutter (Dart), Google Cloud (Gmail + Calendar read-only), Cloudflare Pages, Render.

## Team Contributions (paste)

**Bharat Sankar (Lead)** — Product and design (the Anchor concept, the neobrutalist "V2 Duo" UI). Built the full Flutter app (Talk, Focus, Recap, Profile, the live-voice call). Built the AI brain on the OpenAI API: the judgment engine (the "no"), the conversational companion, the memory-reflection pass, live voice via OpenAI Realtime, and the Exa web-search grounding tool. Built the marketing site.

**Mary Sophiya (Member)** — Import from a ChatGPT or Claude export into Anchor's user-pattern schema, and the read-only Google Calendar + Gmail integration that feeds real load signals.

**Merlin Jose (Member)** — The Supabase database (Postgres schema, 16 tables) and the Node + TypeScript API (judgment seam, commitments, nudges, weekly review), plus the Android build and CI.

## Additional Links
1. `https://anchor-4zt.pages.dev` — Anchor website (with the live app embedded)
2. `https://anchor-4zt.pages.dev/how-it-works.html` — How it works (deep dive + the science)
3. `https://github.com/mpbharat/Anchor` — GitHub repository

## Prior Work
Before the event we created the product concept, the UI design (a neobrutalist design system and screen mockups), a written build spec, and a scaffolded monorepo: the Supabase schema, Node/Express API stubs returning mock data, and a static Flutter front end. During the hackathon we built the agent's intelligence: the OpenAI judgment engine, the conversational companion, the memory-reflection pass, the Exa web-search grounding, the OpenAI Realtime voice loop, the live import and Google integration, and wired every screen to real data.

## Project Video (2 min) — TODO before submit
1. Talk to Anchor by voice: "how's my week looking?" → it lists your four and says it would guard them.
2. Try to add a fifth → **Anchor says no**, reflecting your load (the hero shot).
3. Log gym progress on Focus; open the Pulse-style detail with the log.
4. Show the silence log / a nudge.
5. End-of-week Recap: kept vs slipped, one miss forgiven.
Record → YouTube (Unlisted/Public) or Loom (shareable) → paste the URL.

## Social Media Posts — TODO (post, then paste URLs)

**X / Twitter**
> We built **Anchor** at #AgentsEverywhere: a commitment agent that lives on your phone and says no when you overcommit. It holds you to three or four things a week, learns how you overcommit, and talks to you live by voice.
>
> OpenAI for the judgment and memory, @openrouter for voice, @exaailabs to ground its push-back in real sources.
>
> Thanks @AITinkerers @OpenAI @openrouter @exaailabs

**LinkedIn** (company names: AI Tinkerers, OpenAI, OpenRouter, Exa)
> We built **Anchor** at the Agents Everywhere hackathon: a commitment agent that lives on your phone and says no when you overcommit. It holds you to a few things a week, reads your real load, learns your patterns, and talks to you live by voice. When it has nothing worth saying, it stays quiet and logs every silent call. Built with OpenAI, OpenAI Realtime, Exa, OpenRouter, Supabase, and Flutter. #AgentsEverywhere

## Pre-submit checklist
- [ ] Project Name = Anchor
- [ ] Paste description + team contributions + prior work
- [ ] Tick AI Tinkerers / OpenAI / OpenRouter / Exa; fill Other
- [ ] Add the 3 links
- [ ] Record + paste 2-min video
- [ ] Post + paste social URL(s)
- [ ] Rotate all API keys after the event (shared in chat)

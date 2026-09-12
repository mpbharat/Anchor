# Anchor — Hackathon Submission (Team: The Crawlers)

Deadline: **today 4:30 PM +04**. Draft-ready content for every field. Paste, post, done.

---

## Team Name
The Crawlers

## Project Name
**Anchor**

> Note: the form currently has "The Crawlers" in the Project Name field. That is the team name. The product is **Anchor** — use that on the leaderboard unless you decide otherwise.

---

## Project Description

Anchor is a commitment and accountability agent that lives inside your phone, the place where you already plan your week, get pinged, and overcommit. Most productivity tools help you add more. Anchor does the opposite: it holds you to three or four things a week and pushes back when you try to take on a fifth. That refusal is the product.

The environment is the point. Because Anchor lives on the device with your notifications, calendar, and mail, it sees your real load, not a self-report. When a purchase email or a new calendar invite would push you past your limit, Anchor speaks up in the moment. When nothing needs saying, it stays silent, and every silent judgment is logged, so you can see everything it chose not to interrupt you with. A standalone chatbot cannot do this. It has no presence in the context where commitments are actually made and broken.

You talk to Anchor by voice, like a coach who knows your week. It reasons with the OpenAI model over your live commitments, applies behavioral science (implementation intentions, work-in-progress limits, self-forgiveness on a miss instead of shame), and grounds its push-back in real sources through Exa web search, so when it says a deadline is unrealistic it can show you why. The voice layer runs on OpenRouter.

Technical execution: a Flutter app (one codebase for iOS and Android) on a Supabase backend (Postgres, Auth, Edge Functions) with a Node/Express and TypeScript API. OpenAI drives the judgment and companion. OpenRouter powers voice. Exa grounds the coaching. Google Calendar and Gmail feed read-only load signals. The result is an agent that protects your attention instead of competing for it.

---

## Products & Tools Used (checkboxes to tick)
- [x] AI Tinkerers
- [x] OpenAI
- [x] OpenRouter
- [x] Exa
- [ ] CopilotKit
- [ ] Trigger.dev
- [ ] Auth0
- [ ] Mozilla.ai
- [ ] Ambiguous AI

**Other Products field:** Supabase (Postgres, Auth, Edge Functions), Flutter (Dart), Google Cloud (Gmail + Calendar read-only, Firebase Cloud Messaging for nudges).

---

## Team Contributions

**Bharat Sankar (Lead)** — Product, design, and the AI brain plus the front end. Defined the Anchor concept and the neobrutalist "V2 Duo" design system. Built the full Flutter app (iOS and Android): Load, Commit, Declined (the "no"), Talk (always-on voice companion), and Standing. Built the AI judgment and companion layer on the OpenAI API, the Exa web-search grounding tool (POST /companion/web-search via exa-js), and the OpenRouter voice wiring.

**Mary Sophiya (Member)** — Import and Google integration. Built the history-extraction layer (Python) that turns a ChatGPT or Claude export into Anchor's user-pattern schema using the OpenAI API, and the read-only Google Calendar and Gmail integration that feeds real load signals into the nudge engine.

**Merlin Jose (Member)** — Backend and data. Built the Supabase database (Postgres schema, 16 tables) and the Node/Express and TypeScript API, including the judgment seam, the nudge scheduler, and the cap enforcement and weekly-review logic.

> Verify before submitting: Mary's extraction should be on the **OpenAI API** for sponsor alignment (the Groq→OpenAI swap). If that swap did not land, change her blurb to name the actual provider.

---

## Additional Links
1. `https://github.com/mpbharat/Anchor` — GitHub repository (Flutter app, Supabase schema, Node/Express API, AI layer)
2. `<design brief artifact URL>` — Anchor product and design brief (screens, flow, schema, nudge logic, API)  *(paste the 6-tab artifact link)*

---

## Prior Work
In the days before the event we created the product concept, the UI design (a neobrutalist design system and screen mockups), a written build spec, and a scaffolded monorepo: the Supabase schema, Node/Express API stubs returning mock data, and a static Flutter front end wired to mock data.

During the hackathon we built the agent's intelligence: the OpenAI judgment engine (the "no"), the reactive and proactive nudge engine, the silence log, the Exa web-search grounding tool, the OpenRouter voice loop, Mary's live import extraction and Google load-signal integration, and the wiring of every screen to real data.

---

## Project Video (optional, 2 min max)
- [ ] Record the 2-minute demo (script below), upload to YouTube (Unlisted/Public) or Loom (shareable), paste the URL.

**Demo beats (keep to 2:00):**
1. Open Anchor, make three commitments by voice (each captures an if-then).
2. Try to add a fifth by voice → **Anchor says no**, reflecting your load back (the hero shot).
3. A real signal fires a nudge (an Amazon-style email → "you're at 820 of 1k").
4. Show the **silence log** — everything it chose not to say.
5. End-of-week **Standing**: two of three kept, one miss forgiven.

---

## Social Media Posts (Required — you must post; paste URLs into the form)

Tag every account and include **#AgentsEverywhere**.

### X / Twitter version
> We built **Anchor** at #AgentsEverywhere: a commitment agent that lives on your phone and says no when you overcommit.
>
> It holds you to three or four things a week, reads your real load, and logs everything it chose not to interrupt you with.
>
> OpenAI for the judgment, @openrouter for voice, @exaailabs to ground its push-back in real sources.
>
> Thanks @AITinkerers @OpenAI @CopilotKit @openrouter @exaailabs @auth0 @ambiguousio @triggerdotdev @mozillaAI @googlecloud

### LinkedIn version (company names)
> We built **Anchor** at the Agents Everywhere hackathon: a commitment agent that lives on your phone and says no when you overcommit.
>
> Every productivity tool helps you add more. Anchor does the opposite. It holds you to three or four things a week, reads your real load from your notifications and calendar, and pushes back the moment you try to take on a fifth. When it has nothing worth saying, it stays quiet, and it logs every silent call so you can see everything it chose not to interrupt you with.
>
> You talk to it by voice, like a coach who knows your week. It reasons over your commitments with OpenAI, grounds its push-back in real sources with Exa, and runs voice on OpenRouter. Built as a Flutter app on Supabase with a Node and TypeScript API.
>
> Thanks to AI Tinkerers, OpenAI, OpenRouter, Exa, CopilotKit, Auth0, Ambiguous AI, Trigger.dev, Mozilla.ai, and Google Cloud.
>
> #AgentsEverywhere

> I will NOT post these for you (posting on your behalf needs your go-ahead and it is your account). Post them yourself, then paste the URLs into the form.

---

## Pre-submit checklist
- [ ] Project Name = Anchor (not "The Crawlers")
- [ ] Paste Project Description
- [ ] Tick tools: AI Tinkerers, OpenAI, OpenRouter, Exa; fill Other = Supabase, Flutter, Google Cloud
- [ ] Paste three team contribution blurbs (confirm Mary is on OpenAI)
- [ ] Add links: GitHub + design brief artifact
- [ ] Paste Prior Work
- [ ] Record + upload 2-min video, paste URL
- [ ] Post on X and/or LinkedIn, paste at least one URL
- [ ] EXA_API_KEY added to backend/.env so the Exa feature is live for the demo
- [ ] Rotate all API keys after the event (they were shared in chat)

# ai/ — the brain (owner: Bharat)

Anchor's judgment and nudge intelligence. **The prompts here are legal starter content** (prompts are explicitly-allowed building blocks). **The engine logic — the judgment engine, the reactive + proactive nudge engines, the silence log — is net-new on event day.**

## Contents
- `prompts/persona.md` — who Anchor is; the voice rules for every register (coach / counsellor / friend + accountability).
- `prompts/judge.md` — the "no": Motivational-Interviewing style, returns a verdict JSON.
- `prompts/nudge.md` — reactive (event/threshold) and proactive (pattern) nudge decisions.

## The loop (net-new on the day)
Every signal → **match** to a commitment → **judge** (worth interrupting?) → **nudge** or **stay_silent**. Silence is the default and is written to `judgments` with `verdict='stay_silent'` — that's the silence log.

## Patterns copied from Zaasu (see spec §8.6)
- Two LLM calls, **no function-calling**: a Planner emits verdict JSON, a Toner phrases it aloud. A hand-written router maps JSON → DB writes.
- **AI words things, never computes numbers.** Compute counts/totals/streaks in code; hand the model exact figures.
- User context goes in the **user message** as one small JSON blob (from a single snapshot view), not the system prompt.
- Timeout every call; non-throwing fallbacks so a turn never errors; prompt-injection guard as the last line.

Never surface a provider or model name to the user.

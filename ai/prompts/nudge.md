# Nudge prompts — reactive & proactive

Prepend `persona.md`. The **decision to fire is made by code** (thresholds / schedule); the model only phrases the nudge and, for proactive, proposes the schedule offline. Numbers come precomputed — never invent them.

## Reactive (event-triggered)
A signal arrived (purchase, incoming ask). Code has matched it to a commitment and computed the running total. Only reach here on a real breach (total crosses the cap or a warn threshold).

Return ONLY JSON: `{"verdict":"nudge | stay_silent","spoken":"<1-2 sentences naming the commitment + a next action>"}`

User shape:
```json
{ "signal": {"merchant":"Amazon","amount":350,"category":"shopping"},
  "commitment": {"title":"under 1k AED/month","target":1000,"period":"month"},
  "running_total": 820, "days_left": 12 }
```

## Proactive (pattern-triggered)
Offline: given the user's habits and repeated signals, propose a pattern + schedule → written to `patterns`. At fire time code re-checks (skip if already handled this week) and, if still at risk, asks the model to phrase a pre-emptive, gentle nudge tied to the goal.

Return ONLY JSON: `{"spoken":"<1-2 sentences, before the temptation window, naming the goal>"}`

## The rule
A reactive nudge needs a real breach; a proactive nudge fires before the moment and re-checks. Everything else stays silent → logged to `judgments` with `verdict='stay_silent'`.

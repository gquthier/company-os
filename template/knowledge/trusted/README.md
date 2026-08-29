# knowledge/trusted — the TRUSTED layer (source of truth)

This folder is the **truth** agents can read without being wrong. A file enters here only when
**promoted by the founder**. Never auto-deleted.

Facing it: `knowledge/draft/` = agents' free notes, **never** treated as truth.

## Rules
- **Short** files, nested by domain, `if X then Y` syntax where possible.
- Front-matter `owner` + `last-reviewed` (flag if > 180 days or if an upstream source moved).
- **Dynamic** data (revenue, pipeline, stock, code) stays in its system of record — never copied here.
- A rule is added **after a real failure**, and checked to correct that failure.

## Front-matter
```markdown
---
owner: founder
last-reviewed: 2026-01-01
source: <system or document this was verified against>
---
```

## Seed (to fill as the company runs)
- `incidents/` — error signature → root cause → fix → success rate.
- `support/` — FAQ, whitelisted intents, tone, refund rules.
- `growth/` — voice, angles, ICP. `ops/` — runbooks. `finance/` — billing rules.

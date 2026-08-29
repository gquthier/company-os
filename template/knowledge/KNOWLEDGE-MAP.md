# KNOWLEDGE-MAP — where the truth lives (read BEFORE acting)

> Rule R1: lookup-first. This file is the map. Load only what your task needs.
> Pointers, not copies: dynamic data stays in its system of record.

## 1. The company (always start here)
- `COMPANY.md` — identity, offer, customers, money, team, systems, priorities, "never without me".
- `MISSION.md` — the why; the tone; the bar.
- `bus/DECISIONS.md` — what the founder decided, what waits. Read every run.

## 2. Systems of record (the truth of the business)
> One line per system, from `COMPANY.md`. Access details: `connectors/README.md`. Never a secret here.
- **Customers / pipeline:** TODO (tool + what it holds + who reads it)
- **Money:** TODO
- **Customer requests:** TODO
- **Delivery / product:** TODO (if a codebase: repo URL, main branch, where the docs live)
- **Analytics:** TODO
- **Documents:** TODO (drive / wiki — the founder's docs, contracts, brand)

## 3. Promoted knowledge — `knowledge/trusted/`
- `trusted/incidents/` — signature → root cause → fix → what to check first.
- `trusted/support/` — FAQ, whitelisted intents, tone examples, refund rules.
- `trusted/growth/` — voice, angles already used, ICP, what worked / didn't.
- `trusted/ops/` — runbooks, `loop-engineering.md` (the R10 standard).
- `trusted/finance/` — billing rules, invoicing calendar, cost baselines.

## 4. Agent tooling
- `scripts/` — the runtime (`run-agent`, `claim`, `decision`, `consult`, `notify-agent`,
  `notify`, `standup`, `heartbeat`, `sync`, `schedule`, `doctor`, `new-agent`, `route-model`, `log`).
- `policies/` — autonomy tiers, model routing. `agents/TEAM.md` — who to consult.
- Skills / sub-agents installed on this machine: TODO (pointers to their folders).

## 5. Drafts — `knowledge/draft/`
- `draft/learnings/` — one fact per file, dated. `draft/stale-flags.md` — what looks outdated
  in `trusted/`, with proof. `draft/<agent>/` — each agent's working notes, one canonical
  file per subject.

# TEAM.md — the agents of this company (source of truth, read by all)

> The founder is the final decision-maker. Every agent can **consult** any other (see
> §Consultations). Nobody works in a silo. Roster rows are kept between the markers below —
> `scripts/new-agent.sh` appends there.

<!-- roster:start -->
| Agent | Role in one line | Specialty / when to consult it | Inbox |
|---|---|---|---|
| **chief-of-staff** | Orchestrates, aggregates reports, writes the founder's digest, routes orders, escalates | arbitration between agents, priorities, anything that needs the founder | `bus/inbox/chief-of-staff/` |
| **ops** | Costs + health of everything the company runs on (tools, sites, automations, loops) | "what does this cost?", is a system/loop healthy, drifts, quotas | `bus/inbox/ops/` |
| **support** | Customer requests, draft-first, answers only from trusted knowledge | what customers ask, recurring themes, tone of a reply | `bus/inbox/support/` |
| **growth** | Pipeline & demand in the founder's voice: content, outbound, ads, partnerships — proposes | angles, copy, ICP, what was already used, channels | `bus/inbox/growth/` |
| **finance** | Cash, invoices, receivables/payables, spend vs baseline, runway — read-only, alerts | numbers, billing rules, cost of an action, anomalies | `bus/inbox/finance/` |
| **quality** | Inspects what customers actually receive, as a customer would; files issues | perceived quality, bullshit hunting, funnels end-to-end | `bus/inbox/quality/` |
| **reviewer** | The certainty gate: GO / DIG / SIMPLIFY / REJECT on any consequential change; keeps the process map | before any level B/C change, architecture/process questions, complexity | `bus/inbox/reviewer/` |
<!-- roster:end -->

## 🔒 CLAIM before working (anti-duplicate — RULES R8)
The same agent can run in parallel. Before any substantial task:
`scripts/claim.sh take "<scope>" "<agent>"` (REFUSED if already claimed → no duplicate).
Statuses in real time: `CLAIMED → IN-PROGRESS → REVIEW | SHIPPED → DONE`. Registry: `bus/claims.md`.

## 🤝 Consultations between agents (the expected reflex)
**Rule: if the question touches another agent's specialty, consult it instead of guessing.**
Two channels:
1. **Sync (a quick opinion, minutes):** `bash scripts/consult.sh <agent> "<question + context>"`
   → the agent answers with its role sheet + its sources, **OPINION ONLY** (no action).
2. **Async (a task to handle):** drop a `.md` in `bus/inbox/<agent>/` (context + what is
   expected + who asks), then `bash scripts/notify-agent.sh <agent>` to trigger its run.

### Canonical examples
- **support** sees a technical / delivery problem in a request → consults **reviewer** or the
  delivery agent (opinion), and/or drops the issue in the right inbox (task).
- **growth** wants to know **what an acquisition action costs** before proposing it →
  consults **finance** (cost) then **chief-of-staff** if budget arbitration.
- **any agent** about to make a consequential change (level B/C) → **reviewer** MANDATORY before acting.
- **ops** detects a loop burning money → task to the owning agent + FYI **chief-of-staff**.
- **quality** finds a recurring defect → task to the owning agent + signal to **chief-of-staff**.
- **chief-of-staff** needs context → reads AGENTS.md / logs / reports of each agent directly.

### Rules
- Every consultation is **logged on both sides** (`logs/<you>/`: who, what, the answer).
- A consultation = an OPINION. The action stays with the asking agent (and its R2 permissions).
- Loop forbidden: two agents bouncing a question twice → escalate **chief-of-staff**.
- The chief of staff reads this file + every inbox at each standup: a blocked agent gets unblocked.

## Delegation with a trigger
1. Write `bus/inbox/<agent>/<timestamp>-<you>-<subject>.md`.
2. `bash scripts/notify-agent.sh <agent>` — starts its run now (no-op if one is running; it will
   read the inbox in that run). One run per agent at a time (pidfile).

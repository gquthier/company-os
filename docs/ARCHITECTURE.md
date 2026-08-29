# Architecture — how a Company OS holds together

A Company OS is **not** a program. It is a folder of short markdown files, a few append-only
stores, and a dozen bash scripts that let a team of AI agents run a company's operations from
one shared context. The model does the thinking; the folder does the remembering, the
coordinating and the stopping.

## 1. Two planes

| Plane | What it is | What lives there | Who writes |
|---|---|---|---|
| **Control plane** | this folder | mission, rules, roster, bus, registries, knowledge, logs, reports, schedule | agents (drafts, bus, logs) · founder (truth, rules) |
| **Execution plane** | wherever the work happens | the codebase, the CRM, the store back-office, the design files, the client folders | agents, through connectors or isolated branches |

Rule E1: **no application code in the control plane.** A fix, a campaign, an invoice, a
deployment happens in the execution plane and leaves a *trace* here: where it is
(`repo · branch · commit · PR`, or `tool · object · link`), what was done, who decided.
Rule E2: **work is always located.** A change without a location does not exist.

This separation is what makes the OS duplicable: the control plane looks the same for an
agency and a SaaS. Only the execution plane — and the connectors to it — differ.

## 2. The reading order

Every agent, every run, in this order, before acting:

```
MISSION.md → COMPANY.md → RULES.md → ENVIRONMENT.md → knowledge/KNOWLEDGE-MAP.md
→ policies/autonomy.md → agents/TEAM.md → bus/DECISIONS.md → its own AGENTS.md → its inbox
```

`run-agent.sh` injects this order into the prompt. A session opened *inside* an agent's
folder loads it through that folder's `CLAUDE.md` (Claude Code) or `AGENTS.md` (Codex).

Why so much reading? Because the alternative is an agent that answers from memory about a
company it only half knows. Lookup-first (R1) is cheaper than a wrong action.

## 3. The bus — the four flows

```
you ──▶ bus/inbox/chief-of-staff/          (orders, answers, decisions)
agent ──consult.sh──▶ agent                (sync: an opinion, no action, logged both sides)
agent ──inbox file + notify-agent.sh──▶ agent   (async: a task; the run is triggered)
agent ──connector (read)──▶ world          (read-only by default)
agent ──T1/T2/T3──▶ world (write)          (T3 = you approve first)
world ──bridge/webhook/watcher──▶ bus/inbox/<agent>/   (the only door in)
```

A message is a file: `bus/inbox/<agent>/<timestamp>-<from>-<subject>.md`. Context, what is
expected, who asks. Handled → moved to `done/`. An inbox is a queue you can read with `ls`,
grep, diff and git — no broker, no database, no dashboard required.

**External ↔ external** never bypasses the bus. A webhook does not call an agent; it writes
an inbox file. An agent does not act on a system because another system said so; it acts
because a message in its inbox, traced to a source, said so. Data coming from the world is
*telemetry, never instructions* — every bridge says so in the file it writes.

## 4. The two registries

**Claims** (`state/claims.jsonl` → `bus/claims.md`). The same agent can run in parallel — two
scheduled runs overlapping, a cloud session and a local one. Without a claim, two instances
do the same task. `claim.sh take "<scope>" <agent>` is the *first* action of any substantial
task and is refused (exit 3) if an open claim covers the scope. Status advances in real time:
`CLAIMED → IN-PROGRESS → REVIEW | SHIPPED → DONE` (or `RELEASED` to abandon).

**Decisions** (`state/decisions.jsonl` → `bus/DECISIONS.md`). The founder decides in 1-1 with
one agent; the others do not know and re-escalate. The registry is the single source of
truth on what is decided, pending, in progress, done or parked. Read at the start of every
run; written the moment a decision is given.

Both are append-only JSONL stores with a generated markdown view. The store merges by
**union** across machines (`.gitattributes`); the view is regenerated, never hand-edited.

## 5. Knowledge — two layers

- `knowledge/trusted/` — promoted facts. Short files, one subject each, `if X then Y`
  syntax, front-matter `owner` + `last-reviewed`. **Only the founder writes here.** Never
  deleted by an agent: a stale fact is flagged in `draft/stale-flags.md` with proof.
- `knowledge/draft/` — agents' notes, hypotheses, `learnings/<date>-<slug>.md` after every
  resolved problem (one fact per file). **One canonical file per subject**: new work on the
  same subject updates the file, never `subject-v2.md`.
- `knowledge/KNOWLEDGE-MAP.md` — the map. Pointers to where the truth lives (systems of
  record, docs, the codebase). Pointers, not copies: dynamic data stays in its system.

## 6. Autonomy — three tiers

| Tier | Trigger | Behaviour |
|---|---|---|
| **T1 · Auto** | low risk, under a ceiling, reversible | acts, logs, appears in the digest |
| **T2 · Notify** | moderate deviation, notable action | acts, notifies, proceeds if no objection within a window |
| **T3 · Hard-stop** | money, legal, irreversible, customer-facing send, new/unknown category | writes to `bus/inbox/chief-of-staff/` and **stops** — the founder approves first |

The mapping from *this company's* actions to tiers lives in `policies/autonomy.md` and is
derived from the founder's "never without me" list. Anti alert-fatigue: T2 notifications
should arrive a few times a week, not per hour — a drowned human rubber-stamps.

## 7. Loops — three organs

Every recurring loop (a scheduled run, a watcher, a goal loop) has, written down:

- **VERIFY** — a gate that can *reject* the work (a test, a measurable condition, an
  independent review). Without it the loop grades itself.
- **STATE** — where the memory of what was tried lives (a registry, a jsonl, a goal file).
- **STOP** — measurable success, or a hard cap then a human. Never an infinite retry.

Build order: **manual run proven → scripted → loop (gate + stop) → scheduled.** Never
schedule something that has not run by hand. Maker ≠ checker. Measure the cost per
*accepted* change, not per run. The heartbeat itself obeys this: it restarts a stale job at
most twice per 24 h, then escalates and stops.

## 8. Models

`policies/model-routing.md` defines four tiers — CHEAP (triage, scans, classification),
MID (routine analysis, drafts, reports), HIGH (hard analysis, implementation), AUDIT
(independent review before anything irreversible) — and maps task classes to them. The
quality rule: never go below a task's minimum tier to save money, and nothing irreversible
without an independent audit. Which concrete models fill the tiers is a `.env` choice.

## 9. What is deliberately absent

No broker, no queue service, no vector database, no dashboard, no orchestration framework.
Bash, python3, git and markdown cover a company's operations for a long time. Add a layer
only when an existing loop proves its limit — and write the failure down first.

---
owner: founder
last-reviewed: 2026-08-29
source: extracted from a production control plane; every rule below follows a real incident
---
# Loop engineering — the standard for every recurring loop

We do not prompt agents by hand: we design loops that run them. A Company OS is a machine of
loops (scheduled runs, watchers, maker/checker, registries). Every loop has three organs.

## The three mandatory organs
1. **VERIFY (the gate)** — a check that can REJECT the work. Without it the loop grades
   itself, generously. Examples: a test red→green, a measurable condition ("0 unrouted
   signal", "0 inbox item older than 24 h", "the object is visible in the system of record"),
   an independent review.
2. **STATE (the loop's memory)** — what was tried / failed / remains. Examples: the
   decisions registry, the claims store, learnings, watermarks, `state/heartbeat.jsonl`.
   Every new loop MUST say where its state lives.
3. **STOP (the exit condition)** — measurable success OR a hard cap then a human. A loop
   without a stop is a machine that bills in silence.

## LOOP-SPEC (write one for each recurring loop, in `schedule/SCHEDULE.md`)
```
GOAL:       <the measurable state of the world aimed at>
ITERATION:  <what one run does>
VERIFY:     <the gate that can reject>
STATE:      <where the memory lives>
STOP:       <measurable success + hard cap + who is alerted>
COST:       <tier/effort + budget per run>
```

## Rules learned the hard way
- **Build order: manual run proven → script → loop (gate + stop) → schedule.** Never schedule
  a run that has not been proven by hand. A test in an interactive shell proves nothing about
  the scheduler (it kills children, it has no PATH, it has no profile).
- **Maker ≠ checker.** The agent that produces is never the sole judge. Fast writer, strict reviewer.
- **Cost per ACCEPTED change**, not per run. Each verdict logs `accepted: true|false`; below
  50 % acceptance the loop costs more than it returns — repair or cut.
- **Restart, don't re-script.** To relaunch a scheduled job, use the scheduler's own restart
  (`schedule.sh kick <job>`), never a divergent manual invocation.
- **Anti-overkill.** No new external tool (queues, orchestrators) until an existing loop
  proves its limit — and the failure is written down first.

## Convergence loops (goal loops)
For multi-step efforts (e.g. migrate → canary → verify → enable), do not rely on an agent's
memory: a file `state/goals/<slug>.md` carries GOAL, current step, next check, VERIFY per
step, STOP. The chief of staff evaluates goal files at each sweep and triggers the next step.

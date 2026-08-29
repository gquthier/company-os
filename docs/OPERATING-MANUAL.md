# Operating manual — a Company OS, day to day

## A day in the life

```
06:30  heartbeat.sh        every job that should have run has left a signal? restart the stale ones, cap 2/24h
07:00  ops                 costs and health → reports/daily/<date>/ops.md, drifts → bus/inbox/<agent>/
07:30  standup.sh          every agent writes its report; chief-of-staff writes the digest
       └── you read ONE file: reports/daily/<date>/chief-of-staff.md — and the ⏳ rows of bus/DECISIONS.md
every 30 min  support      new requests → drafts (T1/T2) or escalation (T3); sync.sh pushes the state
on signal     any agent    an inbox file + notify-agent.sh → a run within minutes
21:30  (optional) evening brief — only if something significant happened; silence is allowed
```

Your job in that day: read the digest, answer the ⏳ decisions (`decision.sh set …`), drop
orders in `bus/inbox/chief-of-staff/`. That's it. If you find yourself doing more, an agent
is missing a rule or a permission — fix the rule, not the day.

## Giving an order

```bash
cat > bus/inbox/chief-of-staff/$(date +%s)-founder-q3-pricing.md <<'EOF'
# Q3 pricing review
Look at what we charged the last 20 clients vs. the list price. I want the spread, the three
worst discounts and a recommendation. No changes — a proposal by Friday.
EOF
bash scripts/notify-agent.sh chief-of-staff
```

The chief of staff claims it, delegates to `finance` (and maybe `growth`), follows up, and the
answer lands in the digest — with a ⏳ decision if one is needed.

## Recording a decision

The moment you decide something in a conversation with any agent, the agent records it:

```bash
bash scripts/decision.sh set "q3 pricing" "keep list price, cap discounts at 15%, exceptions = founder" DECIDED founder→finance
```

Anything not in the registry will be asked again. That is by design.

## Adding an agent

```bash
bash scripts/new-agent.sh delivery "Client projects: scope, deadlines, handoffs"
```

Then, in this order: rewrite `agents/delivery/AGENTS.md` from `docs/AGENTS-CATALOG.md`; add
its row in `RULES.md` R2 (allowed / forbidden); map its actions in `policies/autonomy.md`;
add its connectors in `connectors/README.md` (variable names only); add a line in
`schedule/jobs.conf`; run it once by hand before scheduling it.

## Promoting knowledge

An agent learns something → `knowledge/draft/learnings/<date>-<slug>.md` + a message in
`bus/inbox/chief-of-staff/` asking for promotion. You read it, and if it is true and
reusable: move it to `knowledge/trusted/<domain>/`, add the front-matter, commit. Agents never
write to `trusted/`; you never let a draft become "true" by habit.

## Running on several machines

- One private remote. Every machine runs `sync.sh` on a schedule (30 min is fine).
- `sync.sh` commits **before** fetching, merges (never rebases), unions the append-only
  stores, regenerates the views, pushes. If a rebase is ever in progress, it refuses and
  writes a note in `bus/inbox/chief-of-staff/` — resolve by hand, never `rebase --abort` blindly.
- Per-machine state (`state/.machine-id`, `state/last-push.txt`) is gitignored: a stamp from
  another machine must never make this one believe it is fresh.
- Do not run the same scheduled job on two machines at once: locks prevent damage, not waste.

## Costs

Every run logs an estimated cost. `ops` aggregates per agent per day and flags any single day
above +40 % of the seven-day average. The metric that matters for a loop is **cost per
accepted change**, not cost per run: a loop whose output is rejected more than half the time
costs more than it returns — fix it or cut it.

## Keeping the OS honest

- Files under 200 lines. One subject per file. One canonical file per subject in `draft/`.
- A rule is added after a failure, and checked to correct that failure.
- Delete from the execution plane's docs what is no longer true (R7). Never delete from
  `trusted/` without the founder.
- `bash tests/smoke.sh` after any change to `scripts/`.

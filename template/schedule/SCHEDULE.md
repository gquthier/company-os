# SCHEDULE.md — the loops, explained (jobs.conf is the source; this is the why)

> Every loop has its LOOP-SPEC (R10). A loop without VERIFY / STATE / STOP is not scheduled.

| Job | Cadence | GOAL | VERIFY | STATE | STOP |
|---|---|---|---|---|---|
| **heartbeat** | 30 min | every enabled job left a fresh signal | signal age ≤ 1.5× cadence | `state/heartbeat.jsonl` | 2 restarts / job / 24 h → message to `ops` (or `chief-of-staff` if ops is stale), then silence |
| **sync** | 30 min | every machine sees the same registries | push succeeded | `state/last-push.txt` | refuses on a pending rebase; note in `bus/inbox/chief-of-staff/` |
| **standup** | daily 07:30 | one digest the founder can read in 3 minutes | each agent's report exists | `reports/daily/<date>/` | one run; missing report = listed in the digest |
| **ops** | daily 07:00 | costs and health known, drifts routed | report + inbox tasks written | its log | one run |
| **support** | 60 min (off until the helpdesk is wired) | 0 request older than 1 h without a draft or an escalation | draft or escalation exists per request | `state/seen-requests.txt` | max N drafts per run; T3 stops |
| **growth** / **finance** / **quality** | daily (off by default) | proposals / alerts / issues written | file exists | their logs | one run |

## Reinstalling on another machine
```bash
git clone <your private remote> ~/company-os && cd ~/company-os
cp .env.example .env            # then fill it
bash scripts/doctor.sh
bash scripts/schedule.sh install
```
Per-machine state is not versioned; jobs use the real path; `claude`/`codex` must be on the
PATH the scheduler sees (`schedule.sh` writes it from `which`).

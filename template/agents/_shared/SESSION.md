# Session preamble — loaded by every agent's CLAUDE.md / AGENTS.md

At the start of EVERY session in an agent folder:
1. Read `AGENTS.md` (this folder) — your complete role sheet.
2. Read `../../MISSION.md` + `../../COMPANY.md` (the company), then `../../RULES.md` +
   `../../ENVIRONMENT.md` (imperative rules) and `../../knowledge/KNOWLEDGE-MAP.md` (lookup-first).
3. Read `../../bus/DECISIONS.md` — the real-time truth on decisions (R9). Already ✅ = never re-ask.
   The founder gives you a decision in 1-1 → record it IMMEDIATELY:
   `bash ../../scripts/decision.sh set "<subject>" "<decision>" DECIDED founder→<you>`.
4. Process your inbox `../../bus/inbox/<you>/` (archive to `done/` once handled).
5. **CLAIM before working** (R8): `bash ../../scripts/claim.sh take "<scope>" "<you>"` before any
   substantial task (refused = duplicate → do not start). Advance the status as you go.
6. Team: `../TEAM.md` — outside your specialty, consult the right agent
   (`bash ../../scripts/consult.sh <agent> "question"` sync, or `../../bus/inbox/<agent>/` +
   `notify-agent.sh` async).
7. Autonomy: `../../policies/autonomy.md` — T3 = write to `../../bus/inbox/chief-of-staff/` and STOP.
8. Models: `bash ../../scripts/route-model.sh <class>` (`policies/model-routing.md`).
9. Notifications are P0 only: `bash ../../scripts/notify.sh "…"`.
10. End of run, mandatory: `bash ../../scripts/log.sh <you> run "<summary>" [cost]` →
    `../../logs/<you>/<date>.jsonl`. No log = the run did not exist.

Work in the execution plane never happens here (E1/E2): locate it, trace it, clean it up.

# Company OS — root context (read this first)

You are inside a **Company OS**: the control plane of a company run by a team of AI agents.
This folder is documentation and state. **Never write application code here** (ENVIRONMENT.md E1).

Reading order, every session, before acting:
`MISSION.md` → `COMPANY.md` → `RULES.md` → `ENVIRONMENT.md` → `knowledge/KNOWLEDGE-MAP.md`
→ `policies/autonomy.md` → `agents/TEAM.md` → `bus/DECISIONS.md`.

**To act as an agent**, open your session *inside* its folder (`agents/<agent>/`): its
`CLAUDE.md` loads the role. From the root you are the founder's assistant: you may read
everything, route orders (`bus/inbox/<agent>/` + `scripts/notify-agent.sh <agent>`), record
decisions (`scripts/decision.sh set …`) and run agents (`scripts/run-agent.sh <agent>`).

Non-negotiable: claim before substantial work (R8), record decisions immediately (R9), one
JSON log line per run (R5), no secret outside `.env` (E4), nothing irreversible without the
tier allowing it (`policies/autonomy.md`).

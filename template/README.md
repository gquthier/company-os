# <Company> OS — control plane

This folder is the **control plane** of the company: what it is, who decides what, and how
work moves between agents. It runs locally with Claude Code or Codex and a scheduler. No server.

| Autonomous (agents) | Founder's call (T3) |
|---|---|
| reading the systems of record, drafting, classifying, reporting | anything that moves money, sends to a customer, deletes, deploys, signs |
| monitoring costs and health, alerting on P0 | pricing, hiring, new tools, new categories of action |
| daily reports, proposals, learnings | promoting a draft to `knowledge/trusted/` |

Start here: `MISSION.md` · `COMPANY.md` · `RULES.md` · `agents/TEAM.md` · `bus/DECISIONS.md`.

```bash
bash scripts/doctor.sh                         # is everything in place?
bash scripts/run-agent.sh chief-of-staff       # one run
bash scripts/standup.sh                        # reports + digest
bash scripts/schedule.sh install               # run it unattended
```

Built from the [Company OS](https://github.com/gquthier/company-os) template.

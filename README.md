<div align="center">

<img src="https://img.shields.io/badge/AGENTIC-OPERATIONS-12A594?style=flat-square&labelColor=12A594&color=1A1A1A" alt="AGENTIC · OPERATIONS">

# Company OS

### A second brain for your company — and the team of agents that runs it.

One folder holds what your company is, who decides what,<br>and how work moves between agents. Every agent reads it before acting.<br>Nothing runs outside it.

<br>

<a href="https://bizos.cc">
<img src="https://img.shields.io/badge/BizOS-build%20autonomous%20companies-0A0A0A?style=for-the-badge&labelColor=0A0A0A" alt="BizOS — build autonomous companies">
</a>

<br><br>

<a href="https://x.com/gauthierthiry"><img src="https://img.shields.io/badge/@gauthierthiry-0A0A0A?style=flat-square&logo=x&logoColor=white" alt="X"></a>
<a href="https://youtube.com/@gquthier"><img src="https://img.shields.io/badge/@gquthier-FF0000?style=flat-square&logo=youtube&logoColor=white" alt="YouTube"></a>

<br>

<sub>Duplicable template · one-question setup · file-based message bus · claims &amp; decisions registries · tiered autonomy · self-healing loops · Claude Code and Codex · any business · zero shared keys</sub>

</div>

---

`company-os` is the control plane that runs [BizOS](https://bizos.cc) every day, stripped of everything specific to BizOS and turned into a template anyone can duplicate.

You answer **one question** about your company. Your agent builds the OS around the answer: a mission, a team of agents with explicit permissions, a bus they talk on, the registries that stop them from stepping on each other, and the loops that keep them running while you sleep.

It works for an agency, a SaaS, an e-commerce store, a local business, a media company, a freelancer. The structure is the same — only the roster and the rules change.

> **A note on language.** The template and the docs are written in English. Your agent runs the setup conversation, and writes your company's files, in whatever language you speak to it.

## Quick start

```bash
git clone https://github.com/gquthier/company-os.git
cd company-os
claude
```

Then, in the conversation:

```
Read SKILL.md and set up my Company OS.
```

Your agent will:

1. **Ask you one question** — the brief you'd give a new chief of staff on their first morning.
2. **Build your OS** in its own folder (default `~/company-os`): `COMPANY.md`, `MISSION.md`, the roster, the permissions table, the autonomy tiers, the connector list, the schedule.
3. **Run the first day** — the chief of staff reads everything, reports what it understood, and lists what it still needs from you.
4. **Install the schedule** (optional) — launchd on macOS, cron on Linux — so the agents keep running without you.

Prefer to skip the conversation? `bash install.sh ~/acme-os` copies the template and initialises a private git repo. Open it with Claude Code or Codex afterwards and fill `COMPANY.md` yourself.

---

## The one question

> **Brief me on your company the way you'd brief a new chief of staff on their first morning.** What you sell and to whom, how the money comes in, who is on the team and who does what, which tools hold the truth (CRM, payments, helpdesk, repo, spreadsheets…), what eats your time every week, which numbers you look at, what's on fire right now — and the short list of things you would never let anyone decide without you.

Everything the OS needs is in that answer. What isn't there becomes a `TODO` in `COMPANY.md`, never an invention. The exact flow lives in [`SKILL.md`](SKILL.md).

---

## What you get

```text
your-company-os/
├── MISSION.md              why the company exists — every agent reads it before deciding
├── COMPANY.md              the context: offer, customers, money, team, systems, priorities
├── RULES.md                R1→R10 — the imperative rules every agent obeys on every run
├── ENVIRONMENT.md          E1→E5 — where things live, what never goes in here
├── agents/
│   ├── TEAM.md             the roster + how agents consult each other
│   ├── chief-of-staff/     orchestrates, digests, routes your orders, escalates
│   ├── ops/                costs + health of everything the company runs on
│   ├── support/            customer requests, draft-first
│   ├── growth/             pipeline and demand — proposes, never publishes or spends
│   ├── finance/            cash, invoices, receivables, runway — read-only, alerts
│   ├── quality/            inspects what customers actually receive
│   ├── reviewer/           the certainty gate: GO / DIG / SIMPLIFY / REJECT
│   └── _template/          scaffold for the agents your business needs
├── bus/
│   ├── inbox/<agent>/      one message = one file; archived to done/ once handled
│   ├── claims.md           who is working on what (generated — anti-duplicate)
│   └── DECISIONS.md        every decision you took, in real time (generated)
├── knowledge/
│   ├── KNOWLEDGE-MAP.md    where the truth lives — read before acting
│   ├── trusted/            promoted facts (you promote; agents never write here)
│   └── draft/              agent notes, learnings, stale flags
├── policies/
│   ├── autonomy.md         T1 auto · T2 notify · T3 hard-stop — mapped to your business
│   └── model-routing.md    which model tier for which class of task
├── connectors/README.md    the systems agents read (read-only by default)
├── schedule/               jobs.conf + SCHEDULE.md — the cadence of every loop
├── scripts/                the runtime (bash + python3, nothing else)
├── state/  logs/  reports/ append-only stores, run logs, daily reports
└── tests/smoke.sh          proves the runtime works before you schedule anything
```

---

## How it works — the four flows

```text
             ┌──────────────────────────────────────────────────────────────┐
             │                        YOU (founder)                         │
             │   orders → bus/inbox/chief-of-staff/    decisions → registry │
             └──────────────┬───────────────────────────────▲───────────────┘
                            │                               │ digest · escalations · P0 notify
   ┌────────────────────────▼───────────────────────────────┴───────────────────────────┐
   │                               CONTROL PLANE (this folder)                          │
   │                                                                                    │
   │   agent ──consult.sh──▶ agent      agent ──inbox + notify-agent.sh──▶ agent        │
   │        (sync advice)                       (async task, triggers a run)            │
   │                                                                                    │
   │   claims.md ◀── claim.sh ── every substantial task     DECISIONS.md ◀── decision.sh │
   │   logs/<agent>/<date>.jsonl ◀── every run              reports/daily/<date>/       │
   └────────────┬───────────────────────────────────────────────────▲───────────────────┘
                │ read-only connectors · T3 gate for any write      │ inbound bridges
   ┌────────────▼───────────────────────────────────────────────────┴───────────────────┐
   │                          THE WORLD (systems of record)                             │
   │      CRM · payments · helpdesk · repo · analytics · calendar · chat · email         │
   └────────────────────────────────────────────────────────────────────────────────────┘
```

1. **You → agents.** You drop an order in the chief of staff's inbox (or through a chat bridge). It decomposes, delegates, follows up, and reports in a digest written for an investor, not a project manager.
2. **Agent ↔ agent.** Sync consultation for an opinion (`consult.sh`), async file in an inbox for a task (`bus/inbox/<agent>/` + `notify-agent.sh`). Every consultation is logged on both sides. An agent that doesn't know consults instead of guessing.
3. **Agents → the world.** Connectors are read-only by default. Any write (send, pay, publish, delete, deploy) goes through the autonomy tiers; T3 means *you approve first*.
4. **The world → agents.** Webhooks, chat bridges and watchers turn external events (a ticket, a failed payment, an error spike, a message from you) into inbox files. The bus is the only door in.

---

## The rules that make it hold

Every rule below was added after a real failure in production. The full text is in [`template/RULES.md`](template/RULES.md).

| Rule | One line |
|---|---|
| **Lookup-first** | Never answer from memory about the company. `KNOWLEDGE-MAP.md` first, then the source of record. |
| **Two knowledge layers** | `trusted/` is truth and only you write there. `draft/` is free for agents. Promotion is your call. |
| **Claim before you work** | `claim.sh take` is the first action of any substantial task. Refused = someone already has it. |
| **Decisions registry** | A decision you took once is never asked again. `decision.sh set` the moment it happens. |
| **Tiered autonomy** | T1 acts and logs · T2 acts and notifies · T3 stops and waits for you. Money and the irreversible are always T3. |
| **Loops have three organs** | VERIFY (a gate that can reject), STATE (what was tried), STOP (a hard cap, then a human). |
| **Log or it didn't happen** | One JSON line per run. No log, no run. |
| **No code in the control plane** | This folder is documentation and state. Work happens in the execution plane, and is always located. |
| **Notifications are P0 only** | Everything else goes in the daily digest. A drowned human rubber-stamps. |
| **Two failures = stop** | Two failed attempts at the same thing → stop, log, escalate. No infinite retries. |

---

## Rosters by business type

The five core agents (chief of staff, ops, support, growth, finance) fit every company. `quality` and `reviewer` are recommended as soon as an agent produces something a customer sees. Then add what your business actually needs — the catalog is in [`docs/AGENTS-CATALOG.md`](docs/AGENTS-CATALOG.md).

| Business | Add |
|---|---|
| **Agency / services** | `delivery` (client projects, deadlines, scope) · `account` (client relationship, renewals) |
| **SaaS / software** | `bugwatch` (signal → root cause → fix, never auto-merged) · `product` (research → proposal → GO) |
| **E-commerce** | `fulfillment` (orders, stock, returns) · `merchandising` (catalog, pricing tests) |
| **Local business** | `bookings` (calendar, no-shows, reminders) · `reputation` (reviews, replies drafted) |
| **Media / creator** | `content` (pipeline, calendar, repurposing) · `community` (comments, DMs, moderation) |
| **Freelance / solo** | start with `chief-of-staff` + `growth` + `finance`, add `delivery` when you have more than three clients |

```bash
bash scripts/new-agent.sh delivery "Client projects: scope, deadlines, handoffs"
```

---

## Running it

```bash
bash scripts/doctor.sh                                  # preflight: tools, files, secrets, jobs
bash scripts/run-agent.sh chief-of-staff --task "…"     # one run, one agent, one task
bash scripts/standup.sh                                 # every agent reports, chief of staff digests
bash scripts/claim.sh list                              # who is working on what
bash scripts/decision.sh list                           # what you decided, what waits for you
bash scripts/schedule.sh install                        # launchd (macOS) or cron (Linux)
bash scripts/heartbeat.sh                               # restarts stale jobs, caps at 2/24h, then escalates
bash scripts/sync.sh "ops: snapshot"                    # commit → merge (union) → push, never rebase
```

Works with **Claude Code** (`claude -p`) and **Codex** (`codex exec`). Pick the engine and the models in `.env`; the routing policy is in `policies/model-routing.md`.

---

## Requirements

- macOS or Linux (WSL2 works), `bash`, `git`, `python3` — nothing to `pip install`.
- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) or [Codex CLI](https://github.com/openai/codex), authenticated.
- A private git remote for your OS if you run it from more than one machine (the sync script needs one).

No API key is bundled or requested by this repo. Your connectors' credentials go in your OS's `.env`, which is gitignored, and nowhere else.

---

## Documentation

- [`SKILL.md`](SKILL.md) — the conversational setup and the operating commands, step by step.
- [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) — the framework: planes, bus, registries, loops, tiers.
- [`docs/AGENTS-CATALOG.md`](docs/AGENTS-CATALOG.md) — rosters and role sheets by business type.
- [`docs/OPERATING-MANUAL.md`](docs/OPERATING-MANUAL.md) — a day in the life; adding an agent; promoting knowledge; multi-machine.
- [`docs/TROUBLESHOOTING.md`](docs/TROUBLESHOOTING.md) — when a job is stale, a claim is stuck, a sync refuses.

---

## Extracted from production

This is not a design exercise. The same structure has run BizOS since July 2026 — a dozen agents, around twenty scheduled loops, several machines, two model providers — and every rule in `RULES.md` exists because its absence cost something: two parallel sessions building the same fix (→ claims), a decision re-escalated five times (→ the registry), a twelve-day split-brain after an interrupted rebase (→ union merge, commit before sync), four runs dying silently under the scheduler (→ VERIFY / STATE / STOP), an inbox drowned in P2 alerts (→ P0-only notifications).

What was removed to make it a template: the product, the vendors, the people, the keys. What was kept: everything that made it hold.

## Contributing

Issues and pull requests are welcome — a new roster for a business type, a connector pattern, a bridge for a chat tool. Keep the control plane free of application code, keep files short, and add the rule only after the failure.

## License

MIT — see [`LICENSE`](LICENSE).

---

<div align="center">

<br>

### Building something that runs itself?

**[bizos.cc](https://bizos.cc)** — build autonomous companies.

<br>

<a href="https://x.com/gauthierthiry"><img src="https://img.shields.io/badge/@gauthierthiry-0A0A0A?style=flat-square&logo=x&logoColor=white" alt="X"></a>
<a href="https://youtube.com/@gquthier"><img src="https://img.shields.io/badge/@gquthier-FF0000?style=flat-square&logo=youtube&logoColor=white" alt="YouTube"></a>

<br><br>

<sub>Built by <a href="https://x.com/gauthierthiry">Gauthier Thiry</a></sub>

</div>

---
name: company-os
description: >
  Build and operate a Company OS — a file-based control plane where a team of AI agents
  runs a company's operations from one shared context (mission, rules, roster, bus,
  claims and decisions registries, tiered autonomy, scheduled loops). Setup takes ONE
  question about the company. Then day-to-day operation: run an agent, run the standup,
  add an agent, promote knowledge, install the schedule, diagnose a stale loop.
  Triggers: "set up my company OS", "company os", "build my company OS", "add an agent to
  my company OS", "run the standup", "install the company OS schedule", "my agents are
  stale", "promote this to trusted".
metadata:
  version: 1.0.0
---

# Company OS — the skill

You are about to build, or operate, a **Company OS**: one folder that holds what a company
is, who decides what, and how work moves between a team of AI agents. Read this whole
file before acting. Speak to the user in the language they use with you; write the
company's files in that language too. The template's structural files stay in English.

## 0. Where am I?

Decide the mode from the filesystem, not from the user's words:

| You find | Mode |
|---|---|
| `template/` next to this `SKILL.md` and no `COMPANY.md` here | **SETUP** — this is the template repo. Build a new OS in its own folder. |
| `COMPANY.md`, `RULES.md`, `agents/TEAM.md` in the current folder (or a parent) | **OPERATE** — you are inside an installed OS. Go to §3. |
| Neither | Ask for the path of the OS, or offer to run SETUP. |

Never build the OS inside the template repo itself. Never write application code into an OS
(`ENVIRONMENT.md` E1). Never ask for a secret in the conversation: credentials go in the OS's
`.env`, typed by the user, and nowhere else.

## 1. SETUP — one question, then build

### 1.1 Preflight (silent unless something is missing)
- `bash`, `git`, `python3` present; `claude` or `codex` on the PATH.
- Target folder: default `~/company-os`; if the user names the company, propose
  `~/<company-slug>-os`. If the folder exists and is not empty, ask before touching it.

### 1.2 The one question
Ask exactly this, in the user's language, then wait:

> **Brief me on your company the way you'd brief a new chief of staff on their first
> morning.** What you sell and to whom, how the money comes in, who is on the team and who
> does what, which tools hold the truth (CRM, payments, helpdesk, repo, spreadsheets…), what
> eats your time every week, which numbers you look at, what's on fire right now — and the
> short list of things you would never let anyone decide without you.

Add one line: *"You can also drop me files or links (a pitch deck, a README, a Notion export,
your website) and I'll read them first."* If sources are given, read them before parsing the
answer. If the user is in a hurry, accept a three-line answer — the OS starts small and grows.

**Do not ask a second question unless a gap makes the OS unsafe** (no idea what money flows
exist, or no "never without me" list). One short follow-up maximum. Everything else becomes
a `TODO` in `COMPANY.md`. Never invent a fact about the company.

### 1.3 Derive the OS from the answer
Work it out before writing anything, then show a ten-line summary and ask for a GO:

1. **`COMPANY.md`** — fill every section of the template from the brief: identity, offer,
   customers, revenue model, team & roles, systems of record, the founder's time sinks, the
   numbers that matter, current priorities, and the **"never without me"** list. Unknown =
   `TODO:` line, kept visible.
2. **`MISSION.md`** — the why in the founder's words (quote them), the conviction, what it
   implies for every agent's decisions. Short. No corporate filler.
3. **Roster** — the five core agents always; add `quality` and `reviewer` if any agent output
   reaches a customer; then the business-type additions from `docs/AGENTS-CATALOG.md`
   (agency → delivery/account; SaaS → bugwatch/product; e-commerce → fulfillment/merchandising;
   local → bookings/reputation; media → content/community; solo → start with three). Create
   each extra agent with `bash scripts/new-agent.sh <slug> "<role>"`, then rewrite its
   `AGENTS.md` from the catalog's role sheet, adapted to this company.
4. **`agents/TEAM.md`** — the roster table with the one-line role and "when to consult" for
   each agent, in this company's vocabulary.
5. **`RULES.md` R2** — the permissions table: for each agent, what it may read/write/do and
   what is forbidden. Every "never without me" item becomes a forbidden cell somewhere.
6. **`policies/autonomy.md`** — the mapping table: which actions of this company are T1 / T2 / T3.
   Money, legal, customer-facing sends, deletions, deployments, pricing → T3 unless the
   founder explicitly whitelisted them in the brief.
7. **`connectors/README.md`** — one row per system of record named in the brief: what it
   holds, which agent reads it, read-only or not, the env variable name it will need
   (name only — never the value).
8. **`knowledge/KNOWLEDGE-MAP.md`** — pointers to where the truth lives (the systems above,
   the docs/links provided, `COMPANY.md`). Pointers, not copies.
9. **`schedule/jobs.conf`** — a sober first cadence: chief-of-staff standup daily, ops daily,
   support every 30–60 min if there is a helpdesk, growth/finance daily or weekly, heartbeat
   and sync every 30 min. Fewer loops beat more loops at the start.
10. **`.env`** — copy of `.env.example` with the variable names the connectors need, values
    empty. Tell the user which ones to fill, and that the file is gitignored.

### 1.4 Write it
- If the target folder is empty: `bash install.sh <target> --slug <company-slug>` from the
  template repo, then `cd <target>`.
- Write the files above. Keep every file under 200 lines. Keep the `<!-- roster:end -->` and
  other markers intact — scripts depend on them.
- `bash scripts/doctor.sh` must be green except for connectors not yet filled.
- `bash tests/smoke.sh` must pass.
- Commit: `bash scripts/sync.sh "company-os: initial setup"` (commits locally; pushes only if
  a remote exists — tell the user how to add a private remote).

### 1.5 First day
Run `bash scripts/run-agent.sh chief-of-staff --task "FIRST DAY: read everything, write
reports/daily/<today>/chief-of-staff.md with (1) what you understood of the company in ten
lines, (2) what each agent will do this week, (3) the TODOs in COMPANY.md you need answered,
(4) the decisions that already wait for the founder. Log your run."`
Show the report to the user. Fix what they correct. Then offer the schedule:
`bash scripts/schedule.sh install` (explain that unattended runs need
`COMPANY_OS_BYPASS_PERMISSIONS=1` in `.env`, and what that means).

## 2. What a good OS looks like when you're done
- The founder can read `MISSION.md` + `COMPANY.md` in five minutes and recognise their company.
- Every agent has a role sheet that says what it **never** does, not only what it does.
- `bus/DECISIONS.md` already lists the "never without me" items as the standing T3 rules.
- `bus/claims.md` is empty. `logs/` has one line: the first-day run.
- Not a single secret, email, phone number or customer name in a tracked file.

## 3. OPERATE — day-to-day commands

| Need | Do |
|---|---|
| Run one agent | `bash scripts/run-agent.sh <agent> [--task "…"] [--engine claude\|codex]` |
| Standup + digest | `bash scripts/standup.sh` |
| Give the chief of staff an order | write `bus/inbox/chief-of-staff/<ts>-founder-<subject>.md`, then `bash scripts/notify-agent.sh chief-of-staff` |
| Ask an agent's opinion (no action) | `bash scripts/consult.sh <agent> "<question + context>"` |
| Record a decision the founder just took | `bash scripts/decision.sh set "<subject>" "<decision>" DECIDED founder→<agent>` |
| See what waits for the founder | `bash scripts/decision.sh list` (⏳ rows) |
| Add an agent | `bash scripts/new-agent.sh <slug> "<role>"`, then edit its `AGENTS.md`, `RULES.md` R2, `policies/autonomy.md`, `schedule/jobs.conf` |
| Promote a draft to trusted | move the file `knowledge/draft/… → knowledge/trusted/…`, add front-matter `owner` + `last-reviewed`, commit. Only the founder does this. |
| Install / list / remove the schedule | `bash scripts/schedule.sh install \| list \| uninstall` |
| A loop looks dead | `bash scripts/heartbeat.sh` then read `logs/schedule/heartbeat.log`; see `docs/TROUBLESHOOTING.md` |
| Sync between machines | `bash scripts/sync.sh "<message>"` — never `git pull --rebase` in an OS |

When you operate inside an OS, you are bound by its `RULES.md` like any agent: read
`bus/DECISIONS.md` first, claim before substantial work, log at the end.

## 4. Hard limits for you, the setup agent
- One question. One optional follow-up. Then build.
- No secrets in chat, in files, in logs. Variable names only.
- No invented facts. `TODO:` beats a plausible guess.
- No application code in the OS. If the company has a codebase, the OS points to it
  (`ENVIRONMENT.md` E2) and agents work there in isolated branches.
- The founder decides what is T3. You propose; you never widen autonomy on your own.

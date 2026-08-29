# ENVIRONMENT.md — rules for managing THIS folder (the control plane)

> This folder is the **control plane**: documentation + coordination + state. Full stop.
> Every agent AND every human working here follows these rules.

## E1 — FORBIDDEN to write application code here
- **No application code** in this folder. No `src/`, no `node_modules`, no build, no "quick
  fix" dropped here.
- Allowed content: **Markdown** (docs, rules, reports, learnings), **JSONL** (stores, logs),
  the **orchestration scripts** in `scripts/` (and nothing else), scheduler configs.
- An agent that needs to write code or change a system does it **elsewhere** (E2) and leaves
  only the documentary trace here.

## E2 — Work lives in the execution plane, ALWAYS located
- The execution plane is wherever the company's work happens: a code repository, a CRM, a
  store back-office, a shared drive, a project tool. Pointers to each live in
  `knowledge/KNOWLEDGE-MAP.md` and `connectors/README.md`.
- If there is a codebase: work in an **isolated branch or worktree created from the
  up-to-date main branch**, never on main, never from a stale checkout. Production changes
  go through a reviewed merge, never a direct push.
- **Traceability is mandatory.** Whenever an agent creates or modifies something, it writes
  in its log AND in its message to the chief of staff the **exact location**:
  `repo · branch · commit · PR` for code, `tool · object · link` for anything else.
  A change without a location = a change that did not happen.
- Clean up after yourself: a finished branch/worktree is removed; a temporary object is deleted.

## E3 — Where to write what (in this folder)
| Content | Location | Who writes |
|---|---|---|
| Truth (promoted docs) | `knowledge/trusted/` | founder only (promotion) |
| Drafts, learnings, hypotheses | `knowledge/draft/` | agents, freely |
| Messages between agents | `bus/inbox/<agent>/` (archive to `done/` once handled) | agents |
| Daily reports | `reports/daily/<date>/<agent>.md` | agents (standup) |
| Run history | `logs/<agent>/<date>.jsonl` | agents (every run) |
| Claims / decisions | `state/*.jsonl` via `scripts/claim.sh` / `scripts/decision.sh` | scripts only |
| Rules / policies | `RULES.md`, `policies/`, this file | founder (directly or via review) |

## E4 — Documentary hygiene
- **Short** files (< 200 lines). One fact/subject per file for learnings.
- **One canonical file per subject in `knowledge/draft/`**: new work on the same subject
  updates or replaces the old draft (deletion allowed in `draft/`), never `subject-v2.md`,
  `subject-final.md`. An agent searching must find ONE version.
- Markdown with front-matter `owner` + `last-reviewed` for anything entering `trusted/`.
- **Never a secret** outside `.env` (gitignored). Never a token in a .md, a log or a commit.
- No duplication: if the information exists in a system of record, **point** to it
  (`knowledge/KNOWLEDGE-MAP.md`), do not copy it.
- Deletion in `trusted/` = founder's decision only (flag stale → the founder decides).
- This folder is a **git repo**: rules/docs evolve through commits (history).

## E5 — Background jobs (do not break)
- The complete, current list of scheduled jobs is **`schedule/jobs.conf`** + `schedule/SCHEDULE.md`.
  Reinstall on another machine, cadences, actions: everything is there.
- Loaded/enabled state is **per machine**: never infer active jobs from this document. Check
  `scripts/schedule.sh list`.
- Do not rename/move `scripts/` without reinstalling the schedule (`scripts/schedule.sh install`).
- Jobs point at the **real path** of this folder. Never replace it with a symlink on macOS
  (TCC would block the jobs).
- Every loop obeys R10 (VERIFY / STATE / STOP). The heartbeat restarts a stale job at most
  twice per 24 h, then escalates and stops.

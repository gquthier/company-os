# Troubleshooting

**A scheduled job never runs.**
`bash scripts/schedule.sh list` — is it loaded? On macOS, `launchctl list | grep company-os`.
The plist must be `chmod 644` and point to the *real* path of the OS (not a symlink on the
Desktop — macOS TCC blocks jobs behind those). The PATH inside the plist must contain the
folder where `claude`/`codex` live (`which claude`); scheduler processes do not read your
shell profile. `logs/schedule/<job>.log` has the error.

**A job runs but dies silently.**
The scheduler killed its children. On macOS every plist needs `AbandonProcessGroup = true`
(`schedule.sh` sets it). Check `bash scripts/run-agent.sh <agent> --dry-run` prints the prompt.

**The heartbeat keeps restarting a job, then escalates.**
That is the STOP organ working: two restarts per 24 h, then a message in `bus/inbox/ops/`
(or `chief-of-staff/` if ops itself is stale). Read `logs/schedule/heartbeat.log`, fix the
cause, and archive the message to `done/`. A job *deliberately* disabled in `jobs.conf`
(`enabled=no`) is never restarted or escalated.

**`claim.sh take` refuses with exit 3.**
An open claim covers that scope — maybe another session, maybe your own previous run that
never closed it. `bash scripts/claim.sh list`; if it is yours and dead,
`bash scripts/claim.sh set <id> RELEASED "stale run"`. Never delete lines from
`state/claims.jsonl`.

**`sync.sh` says a rebase is in progress and refuses.**
Someone ran `git pull --rebase` in the OS. Look at `git status`; finish or abort the rebase
*by hand* after reading what it contains; then run `sync.sh` again. This refusal exists
because an interrupted rebase once hid twelve days of work.

**Two versions of a text file after a sync.**
Text files that conflicted are kept with both versions and an HTML comment marking them,
plus a note in `bus/inbox/chief-of-staff/`. Pick, clean, commit. Views (`bus/claims.md`,
`bus/DECISIONS.md`) are regenerated automatically — never edit them by hand.

**An agent keeps re-asking a decision you already gave.**
It was not recorded. `bash scripts/decision.sh set "<subject>" "<decision>" DECIDED founder→<agent>`.
Then ask the agent why it did not record it in the 1-1 — that is a rule violation (R9).

**Notifications are noisy.**
Only P0 goes to `notify.sh`. If an agent posts P1/P2, its role sheet is wrong: everything
non-P0 belongs in the daily digest. Tighten `RULES.md` R5 for that agent.

**`doctor.sh` flags a secret in a tracked file.**
Remove it, rotate it, and check `git log -p` — a secret that has been committed once is
compromised even after deletion. `.env` is the only home of a secret.

**Unattended runs do nothing / hang on permissions.**
`claude -p` needs `COMPANY_OS_BYPASS_PERMISSIONS=1` in `.env` to act without a human
approving each tool call. Understand what that means before enabling it: the safety net is
then `RULES.md`, read-only connectors and the T3 gate — which is exactly why they exist.

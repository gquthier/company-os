#!/usr/bin/env bash
# lib.sh — shared helpers, sourced by every script of the Company OS runtime. Not executable alone.
# Resolves the OS root, loads .env, provides locks, JSON helpers and the agent roster.
[ -n "${COS_LIB_LOADED:-}" ] && return 0 2>/dev/null
COS_LIB_LOADED=1
COS_ROOT="${COMPANY_OS_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
cd "$COS_ROOT" || exit 1
if [ -f .env ]; then set -a; . ./.env; set +a; fi
COS_SLUG="${COMPANY_OS_SLUG:-company}"

now_iso(){ date "+%Y-%m-%dT%H:%M:%S%z"; }
today(){ date +%F; }
epoch(){ date +%s; }
say(){ echo "[$(now_iso)] $*" >&2; }
json_str(){ python3 -c 'import json,sys;print(json.dumps(sys.argv[1], ensure_ascii=False))' "$1"; }

# Portable lock (macOS has no flock by default): mkdir is atomic on POSIX.
lock_take(){ local d="$1" n=0; until mkdir "$d" 2>/dev/null; do sleep 0.05; n=$((n+1)); [ "$n" -gt 200 ] && { say "lock timeout: $d"; return 1; }; done; return 0; }
lock_drop(){ rmdir "$1" 2>/dev/null || true; }

# Roster = every agents/<slug>/AGENTS.md, except _template/_shared.
agents_list(){ local d n; for d in agents/*/; do d="${d%/}"; n="${d#agents/}"; case "$n" in _*) continue;; esac; [ -f "$d/AGENTS.md" ] && echo "$n"; done; }
agent_exists(){ [ -f "agents/$1/AGENTS.md" ]; }
require_agent(){ agent_exists "$1" || { say "unknown agent: $1 (see agents/TEAM.md)"; exit 1; }; }

# jobs.conf reader: prints "job|cadence|task|enabled" lines, comments and blanks stripped.
jobs_read(){ [ -f schedule/jobs.conf ] || return 0
  grep -vE '^\s*(#|$)' schedule/jobs.conf | while IFS='|' read -r j c t e; do
    j="$(echo "$j" | xargs)"; c="$(echo "$c" | xargs)"; t="$(echo "$t" | xargs)"; e="$(echo "${e:-yes}" | xargs)"
    [ -n "$j" ] && printf '%s|%s|%s|%s\n' "$j" "$c" "$t" "$e"; done; }

# cadence → minutes (every:*) or "" (daily/weekly are checked against ~26h/~8d windows by the heartbeat)
cadence_minutes(){ case "$1" in
  every:*m) echo "${1#every:}" | tr -d m;;
  every:*h) echo $(( ${1#every:} * 60 )) 2>/dev/null || echo $(( $(echo "${1#every:}" | tr -d h) * 60 ));;
  daily:*)  echo 1440;;
  weekly:*) echo 10080;;
  *) echo "";; esac; }

# Guard: refuse any text that looks like a credential (used by sync.sh and doctor.sh).
SECRET_RE='(sk-[A-Za-z0-9_-]{16,}|xox[abp]-[A-Za-z0-9-]{10,}|gh[pousr]_[A-Za-z0-9]{20,}|AKIA[0-9A-Z]{16}|-----BEGIN [A-Z ]*PRIVATE KEY-----|eyJ[A-Za-z0-9_-]{20,}\.[A-Za-z0-9_-]{20,}\.[A-Za-z0-9_-]{10,})'
# secret_scan: reads STDIN, exit 0 if a credential-like pattern appears on an ADDED line (any line with --any).
# Python (-c, so stdin stays the pipe), not grep: grep implementations differ (GNU/BSD/ugrep) and
# some reject this pattern's complexity.
secret_scan(){ python3 -c '
import re, sys
rx = re.compile(sys.argv[1]); anyline = sys.argv[2] == "--any"
found = False
for line in sys.stdin.buffer:   # drain to EOF: an early exit would SIGPIPE the producer under pipefail
    t = line.decode("utf-8", "replace")
    if not found and (anyline or t.startswith("+")) and rx.search(t): found = True
sys.exit(0 if found else 1)' "$SECRET_RE" "${1:-}"; }

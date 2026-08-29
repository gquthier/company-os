#!/usr/bin/env bash
{ # parse-whole-file guard (see run-agent.sh)
# sync.sh "<message>" — the ONLY git sync organ of this OS. commit → fetch → merge (union) → push.
# Why it exists: registries written by claim.sh/decision.sh must reach every machine, and the
# naive `git pull --rebase --autostash` after writing once trapped a fresh claim in an autostash
# and left an interrupted rebase that disarmed every other sync for twelve days.
# Therefore: 1) COMMIT BEFORE synchronising (nothing dirty → nothing to stash → nothing lost);
#            2) MERGE, never rebase (append-only stores are merge=union via .gitattributes);
#            3) conflicts resolved by CLASS: views → regenerated · everything else → both
#               versions kept + a note in bus/inbox/chief-of-staff/. Never a marker left behind.
# Exit: 0 pushed · 1 nothing pushed but local state committed and safe · 2 REFUSED (git op pending).
set -uo pipefail
. "$(dirname "$0")/lib.sh"
[ "${COMPANY_OS_NOSYNC:-}" = "1" ] && exit 0
MSG="${1:-ops: sync $(hostname -s 2>/dev/null || hostname) $(date '+%F %H:%M')}"
mkdir -p state bus/inbox/chief-of-staff; LOCK="state/.sync.lock.d"; STAMP="state/last-push.txt"
git rev-parse --is-inside-work-tree >/dev/null 2>&1 || { say "sync: not a git repository"; exit 1; }
if ! mkdir "$LOCK" 2>/dev/null; then
  if [ -n "$(find "$LOCK" -maxdepth 0 -mmin +30 2>/dev/null)" ]; then rmdir "$LOCK" 2>/dev/null; mkdir "$LOCK" 2>/dev/null || { say "sync: lock held"; exit 1; }
  else say "sync: another sync is running"; exit 1; fi
fi
trap 'rmdir "$LOCK" 2>/dev/null' EXIT
note(){ local f="bus/inbox/chief-of-staff/sync-$(hostname -s 2>/dev/null || echo host)-$1.md"
  printf '# git sync — %s (%s)\n\n%s\n\nLast known push: %s\nHEAD=%s branch=%s\n' "$1" "$(now_iso)" "$2" "$(cat "$STAMP" 2>/dev/null || echo never)" "$(git rev-parse --short HEAD 2>/dev/null)" "$(git rev-parse --abbrev-ref HEAD 2>/dev/null)" > "$f"; say "$1 → $f"; }
if [ -d .git/rebase-merge ] || [ -d .git/rebase-apply ]; then
  note rebase-pending "A rebase is in progress in this OS. sync.sh REFUSES to act. Inspect \`git status\`, finish or abort it BY HAND after reading what it holds, then run sync.sh again. Never \`rebase --abort\` blindly."; exit 2; fi

# 1) secret guard, then commit everything (local safety first)
git add -A >/dev/null 2>&1
for f in .env .env.*; do [ -e "$f" ] && [ "$f" != .env.example ] && git reset -q -- "$f" >/dev/null 2>&1; done; true
if git diff --cached | secret_scan; then
  git reset -q; note secret-blocked "A staged change looked like a credential. Nothing was committed. Move it to .env (gitignored), rotate it, and run sync.sh again."; exit 1; fi
git diff --cached --quiet || git commit -q -m "$MSG" 2>/dev/null || true

# 2) fetch + merge (union)
git remote get-url origin >/dev/null 2>&1 || { say "sync: no remote 'origin' — committed locally only"; exit 1; }
BR="$(git rev-parse --abbrev-ref HEAD)"; [ "$BR" = HEAD ] && { note detached-head "HEAD is detached. Commit is local. Run: git checkout main (or your branch) and merge this commit by hand."; exit 1; }
git fetch -q origin "$BR" 2>/dev/null || { say "sync: fetch failed (offline?) — committed locally"; exit 1; }
if ! git merge -q --no-edit "origin/$BR" >/dev/null 2>&1; then
  CONFLICTS="$(git diff --name-only --diff-filter=U)"
  for f in $CONFLICTS; do
    case "$f" in
      bus/claims.md|bus/DECISIONS.md) git checkout -q --ours -- "$f" 2>/dev/null || true ;;   # regenerated below
      *) python3 - "$f" <<'PY'
import re, sys
p = sys.argv[1]; s = open(p, encoding="utf-8", errors="replace").read()
s = re.sub(r"^<<<<<<< [^\n]*\n", "<!-- sync conflict: this machine's version -->\n", s, flags=re.M)
s = re.sub(r"^=======\n", "<!-- sync conflict: other machine's version -->\n", s, flags=re.M)
s = re.sub(r"^>>>>>>> [^\n]*\n", "<!-- sync conflict: end — pick, clean, commit -->\n", s, flags=re.M)
open(p, "w", encoding="utf-8").write(s)
PY
      ;;
    esac
    git add -- "$f" 2>/dev/null || true
  done
  bash scripts/claim.sh render >/dev/null 2>&1 || true; bash scripts/decision.sh render >/dev/null 2>&1 || true
  git add -A >/dev/null 2>&1
  if git grep -qE '^(<<<<<<<|=======|>>>>>>>)' -- . 2>/dev/null; then note markers-left "Conflict markers remain after resolution — merge NOT committed. Resolve by hand."; git merge --abort 2>/dev/null; exit 1; fi
  git commit -q -m "sync: union merge with conflicts kept both versions ($(echo "$CONFLICTS" | tr '\n' ' '))" 2>/dev/null || true
  note conflicts "Files that conflicted and now hold BOTH versions (marked with HTML comments): $(echo "$CONFLICTS" | tr '\n' ' '). Pick, clean, commit."
fi

# 3) push (3 tries: another machine may push in between)
for i in 1 2 3; do
  if git push -q origin "HEAD:$BR" 2>/dev/null; then echo "$(epoch) $(now_iso)" > "$STAMP"; say "sync: pushed $BR"; exit 0; fi
  git fetch -q origin "$BR" 2>/dev/null && git merge -q --no-edit "origin/$BR" >/dev/null 2>&1 || true; sleep 2
done
note push-failed "Push failed 3 times. Local state is committed and safe. Check the remote / credentials."; exit 1
}; exit $?

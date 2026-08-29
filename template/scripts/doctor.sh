#!/usr/bin/env bash
# doctor.sh — preflight of this Company OS: tools, files, roster, secrets, git, schedule.
set -uo pipefail
. "$(dirname "$0")/lib.sh"
OK=0; KO=0; WARN=0
pass(){ echo "  ✅ $1"; OK=$((OK+1)); }; fail(){ echo "  ❌ $1"; KO=$((KO+1)); }; warn(){ echo "  ⚠️  $1"; WARN=$((WARN+1)); }
echo "COMPANY OS DOCTOR · $COS_ROOT · slug=$COS_SLUG"
echo "── tools"
for t in bash git python3; do command -v "$t" >/dev/null && pass "$t" || fail "$t missing"; done
if command -v claude >/dev/null; then pass "claude CLI"; elif command -v codex >/dev/null; then pass "codex CLI"; else fail "no engine: install Claude Code or Codex CLI"; fi
echo "── files"
for f in MISSION.md COMPANY.md RULES.md ENVIRONMENT.md agents/TEAM.md knowledge/KNOWLEDGE-MAP.md policies/autonomy.md policies/model-routing.md connectors/README.md schedule/jobs.conf; do [ -f "$f" ] && pass "$f" || fail "$f missing"; done
[ -f .env ] && pass ".env present" || warn ".env missing (cp .env.example .env)"
n="$(grep -c 'TODO' COMPANY.md 2>/dev/null || echo 0)"; [ "$n" -gt 0 ] && warn "COMPANY.md still has $n TODO — the chief of staff will ask" || pass "COMPANY.md has no TODO"
echo "── roster"
for a in $(agents_list); do
  [ -f "agents/$a/CLAUDE.md" ] || warn "agents/$a/CLAUDE.md missing (sessions inside the folder will not load the role)"
  [ -d "bus/inbox/$a" ] || { mkdir -p "bus/inbox/$a/done"; warn "created bus/inbox/$a/"; }
  grep -q "\*\*$a\*\*" agents/TEAM.md 2>/dev/null && pass "$a (TEAM.md, inbox)" || warn "$a not in agents/TEAM.md roster"
done
echo "── secrets"
if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  hit="$(git ls-files | while read -r f; do [ -f "$f" ] && secret_scan --any < "$f" && echo "$f"; done | head -5)"
  [ -z "$hit" ] && pass "no credential pattern in tracked files" || fail "credential-like pattern in: $(echo "$hit" | tr '\n' ' ') — move to .env, rotate"
  git check-ignore -q .env && pass ".env is gitignored" || fail ".env is NOT gitignored"
else warn "not a git repository (run: git init)"; fi
echo "── git"
if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  if git remote get-url origin >/dev/null 2>&1; then
    git push --dry-run origin HEAD >/dev/null 2>&1 && pass "origin reachable (push dry-run)" || warn "origin set but push dry-run failed (auth? offline?)"
  else warn "no remote 'origin' — add a PRIVATE one before running on several machines"; fi
  { [ -d .git/rebase-merge ] || [ -d .git/rebase-apply ]; } && fail "a rebase is in progress — resolve by hand" || pass "no pending git operation"
fi
echo "── schedule"
if [ "$(uname)" = Darwin ]; then c="$(launchctl list 2>/dev/null | grep -c "com.company-os.$COS_SLUG" || true)"; else c="$(crontab -l 2>/dev/null | grep -c "company-os:$COS_SLUG" || true)"; fi
[ "${c:-0}" -gt 0 ] && pass "$c scheduled job(s) loaded" || warn "no job loaded on this machine (bash scripts/schedule.sh install)"
[ "${COMPANY_OS_BYPASS_PERMISSIONS:-0}" = "1" ] && pass "unattended runs enabled" || warn "COMPANY_OS_BYPASS_PERMISSIONS≠1: scheduled runs cannot act (see docs/TROUBLESHOOTING.md)"
echo "$OK ok · $WARN warnings · $KO errors"
[ "$KO" -eq 0 ]

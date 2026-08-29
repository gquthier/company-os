#!/usr/bin/env bash
# smoke.sh — proves the runtime works BEFORE anything is scheduled (RULES R10: manual run proven first).
# Runs on a throwaway copy of this OS with sync disabled and no engine call. Exit ≠ 0 = broken.
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
TMP="$(mktemp -d 2>/dev/null || mktemp -d -t cos)"; trap 'rm -rf "$TMP"' EXIT
cp -R "$HERE"/. "$TMP"/ 2>/dev/null; rm -rf "$TMP/.git" "$TMP/state"/*.jsonl "$TMP/state"/.*.lock.d 2>/dev/null
cd "$TMP"; export COMPANY_OS_NOSYNC=1 COMPANY_OS_DIR="$TMP" COMPANY_OS_SLUG=smoke HOME="${HOME:-/tmp}"
[ -f .env ] || cp .env.example .env
FAIL=0; t(){ if "$@" >/dev/null 2>&1; then echo "  ✅ $*"; else echo "  ❌ $*"; FAIL=1; fi; }
tn(){ if "$@" >/dev/null 2>&1; then echo "  ❌ (should fail) $*"; FAIL=1; else echo "  ✅ (fails as expected) $*"; fi; }
echo "SMOKE · $TMP"
echo "── syntax"; for f in scripts/*.sh tests/*.sh; do t bash -n "$f"; done
echo "── claims"
ID="$(bash scripts/claim.sh take "smoke: task A" ops "test" 2>/dev/null | tail -1)"; [ -n "$ID" ] && echo "  ✅ take → $ID" || { echo "  ❌ take"; FAIL=1; }
bash scripts/claim.sh take "smoke: task A" support >/dev/null 2>&1; rc=$?; [ "$rc" = 3 ] && echo "  ✅ duplicate refused (exit 3)" || { echo "  ❌ duplicate not refused (rc=$rc)"; FAIL=1; }
t bash scripts/claim.sh set "$ID" IN-PROGRESS; t bash scripts/claim.sh set "$ID" DONE
tn bash scripts/claim.sh set "$ID" BOGUS
grep -q "smoke: task A" bus/claims.md && echo "  ✅ view rendered" || { echo "  ❌ view"; FAIL=1; }
bash scripts/claim.sh take "smoke: task A" support >/dev/null 2>&1 && echo "  ✅ re-take after DONE allowed" || { echo "  ❌ re-take after DONE"; FAIL=1; }
echo "── decisions"
t bash scripts/decision.sh set "smoke pricing" "keep list price" DECIDED "founder→finance"
t bash scripts/decision.sh show "pricing"; tn bash scripts/decision.sh show "nothing-here"; tn bash scripts/decision.sh set x y BOGUS
grep -q "smoke pricing" bus/DECISIONS.md && echo "  ✅ view rendered" || { echo "  ❌ view"; FAIL=1; }
echo "── log / route / notify"
t bash scripts/log.sh ops run "smoke run" 0.01 '{"accepted":true}'
grep -q '"accepted": true' "logs/ops/$(date +%F).jsonl" && echo "  ✅ jsonl line" || { echo "  ❌ jsonl"; FAIL=1; }
t bash scripts/route-model.sh classify; t bash scripts/route-model.sh ship; t bash scripts/route-model.sh diagnose --hard
t bash scripts/notify.sh "smoke P0 (no channel → log only)"
echo "── agents"
t bash scripts/new-agent.sh delivery "Client projects: scope, deadlines"
[ -f agents/delivery/AGENTS.md ] && grep -q 'delivery' agents/TEAM.md && echo "  ✅ scaffold + roster row" || { echo "  ❌ scaffold"; FAIL=1; }
tn bash scripts/new-agent.sh delivery "dup"
DRY="$(bash scripts/run-agent.sh delivery --task "hello" --dry-run 2>/dev/null)"; printf '%s' "$DRY" | grep -q "agent 'delivery'" && echo "  ✅ run-agent dry-run prompt" || { echo "  ❌ run-agent dry-run"; FAIL=1; }
tn bash scripts/run-agent.sh nobody --dry-run
CON="$(COMPANY_OS_DRY_RUN=1 bash scripts/consult.sh reviewer "is this ok?" 2>/dev/null)"; printf '%s' "$CON" | grep -q "OPINION ONLY" && echo "  ✅ consult prompt" || { echo "  ❌ consult"; FAIL=1; }
echo "── heartbeat"
t bash scripts/heartbeat.sh
# make ops look stale (signal 1 day old, cadence daily → window 36h → still fresh); then 3 days old → restart
touch -t "$(date -v-3d +%Y%m%d%H%M 2>/dev/null || date -d '3 days ago' +%Y%m%d%H%M)" "logs/ops/$(date +%F).jsonl" 2>/dev/null
HEARTBEAT_NOW_EPOCH=$(date +%s) bash scripts/heartbeat.sh >/dev/null 2>&1
grep -q "restart ops" logs/schedule/heartbeat.log && echo "  ✅ stale job restarted" || { echo "  ❌ stale job not restarted"; FAIL=1; }
echo "── doctor (errors only fail)"; bash scripts/doctor.sh >/dev/null 2>&1; rc=$?; [ "$rc" = 0 ] && echo "  ✅ doctor" || echo "  ⚠️  doctor rc=$rc (engine/.env may be missing in CI — not fatal here)"
echo "── secret guard"
# fake credentials are BUILT at runtime so this file never contains a credential-like literal
FAKE1="xoxb-$(printf '1%.0s' {1..12})-abcdefghijkl"; FAKE2="sk-$(printf 'a%.0s' {1..36})"
printf '+token %s\n' "$FAKE1" | bash -c '. scripts/lib.sh; secret_scan' && echo "  ✅ secret_scan detects" || { echo "  ❌ secret_scan blind"; FAIL=1; }
printf '+hello world\n' | bash -c '. scripts/lib.sh; secret_scan' && { echo "  ❌ secret_scan false positive"; FAIL=1; } || echo "  ✅ secret_scan clean line"
git init -q . 2>/dev/null && git -c user.name=smoke -c user.email=smoke@localhost commit -q --allow-empty -m init 2>/dev/null
echo "key = $FAKE2" > knowledge/draft/leak.md
COMPANY_OS_NOSYNC= bash scripts/sync.sh "leak test" >/dev/null 2>&1; git ls-files --error-unmatch knowledge/draft/leak.md >/dev/null 2>&1 && { echo "  ❌ secret committed"; FAIL=1; } || echo "  ✅ secret blocked"
rm -f knowledge/draft/leak.md; COMPANY_OS_NOSYNC= bash scripts/sync.sh "clean commit" >/dev/null 2>&1; git ls-files --error-unmatch RULES.md >/dev/null 2>&1 && echo "  ✅ clean tree committed by sync" || { echo "  ❌ sync did not commit a clean tree"; FAIL=1; }
[ "$FAIL" = 0 ] && echo "SMOKE OK" || { echo "SMOKE FAILED"; exit 1; }

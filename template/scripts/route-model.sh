#!/usr/bin/env bash
# route-model.sh <class> [--hard] — which tier/engine/model for a task class (policies/model-routing.md).
# Classes: research scan triage classify | draft report read | analyze diagnose implement | ship
# Prints one PLAN line. Side effect: counts provider usage in state/usage.json when balancing is on.
set -euo pipefail
. "$(dirname "$0")/lib.sh"
CLASS="${1:-}"; shift || true; HARD=0
while [ $# -gt 0 ]; do case "$1" in --hard) HARD=1;; esac; shift; done
[ -n "$CLASS" ] || { echo "usage: route-model.sh <class> [--hard]" >&2; exit 1; }
USAGE="${COMPANY_OS_USAGE_FILE:-state/usage.json}"; mkdir -p state
[ -f "$USAGE" ] || echo '{"claude":0,"codex":0}' > "$USAGE"

tier_of(){ case "$1" in
  research|scan|triage|classify) echo CHEAP;;
  draft|report|read) echo MID;;
  analyze|diagnose|implement) echo HIGH;;
  ship) echo AUDIT;;
  *) echo HIGH;; esac; }
model_for(){ local v="COMPANY_OS_MODEL_$1"; local m="${!v:-}"; echo "${m:-${COMPANY_OS_MODEL:-<cli-default>}}"; }
pick_engine(){ # balance only when enabled and both engines exist
  if [ "${COMPANY_OS_BALANCE_PROVIDERS:-0}" = "1" ] && command -v claude >/dev/null && command -v codex >/dev/null; then
    python3 - "$USAGE" <<'PY'
import json, sys
f = sys.argv[1]; u = json.load(open(f))
p = "codex" if u.get("codex", 0) < u.get("claude", 0) else "claude"
u[p] = u.get(p, 0) + 1; json.dump(u, open(f, "w")); print(p)
PY
  else echo "${COMPANY_OS_ENGINE:-claude}"; fi; }

TIER="$(tier_of "$CLASS")"; ENGINE="$(pick_engine)"
case "$TIER" in
  AUDIT)  echo "AUDIT · author run ≠ auditor run · model $(model_for AUDIT) · both must converge, else escalate to the founder";;
  HIGH)   if [ "$HARD" = 1 ] && [ "$CLASS" = diagnose ]; then echo "HIGH×2 · two independent runs ($(model_for HIGH)) · compare hypotheses before acting"
          else echo "HIGH · $ENGINE · $(model_for HIGH)"; fi;;
  MID)    echo "MID · $ENGINE · $(model_for MID)";;
  CHEAP)  echo "CHEAP · $ENGINE · $(model_for CHEAP)";;
esac
[ "$(tier_of "$CLASS")" = HIGH ] && [ "$CLASS" != analyze ] && [ "$CLASS" != diagnose ] && [ "$CLASS" != implement ] && echo "(unknown class '$CLASS' → prudent default HIGH)" >&2 || true

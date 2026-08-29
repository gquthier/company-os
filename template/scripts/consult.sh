#!/usr/bin/env bash
# consult.sh <agent> "<question + context>" — SYNC consultation between agents.
# The consulted agent answers from its role sheet + its sources, OPINION ONLY (no action, no
# send, no write except its log). Logged on both sides (RULES R5, TEAM.md).
set -euo pipefail
. "$(dirname "$0")/lib.sh"
AGENT="${1:?usage: consult.sh <agent> \"question\"}"; Q="${2:?question missing}"
require_agent "$AGENT"
ENGINE="${COMPANY_OS_ENGINE:-claude}"; MODEL="${COMPANY_OS_MODEL_HIGH:-${COMPANY_OS_MODEL:-}}"
[ "$AGENT" = reviewer ] && MODEL="${COMPANY_OS_MODEL_AUDIT:-$MODEL}"
mkdir -p "logs/$AGENT"
read -r -d '' PROMPT <<EOF || true
You are the agent '$AGENT' of this Company OS (role sheet: agents/$AGENT/AGENTS.md — read it, plus agents/TEAM.md,
COMPANY.md and knowledge/KNOWLEDGE-MAP.md if useful).
CONSULTATION from another agent of the team (OPINION ONLY — you take NO action, send nothing, write nothing except your log):
$Q
Answer in ≤ 12 lines: your expert answer, your sources (files / data consulted), your confidence level, and what you
recommend next. If the question is outside your specialty → say so and point to the right agent (TEAM.md).
Finish by running: bash scripts/log.sh $AGENT consult "<subject> · confidence <low|medium|high>".
EOF
if [ "${COMPANY_OS_DRY_RUN:-0}" = "1" ]; then printf '%s\n' "$PROMPT"; exit 0; fi
BYPASS=""; [ "${COMPANY_OS_BYPASS_PERMISSIONS:-0}" = "1" ] && BYPASS="--dangerously-skip-permissions"
case "$ENGINE" in
  claude) claude -p $BYPASS ${MODEL:+--model "$MODEL"} "$PROMPT" 2>&1 | tail -16 ;;
  codex)  codex exec ${MODEL:+-c model="$MODEL"} "$PROMPT" 2>&1 | tail -16 ;;
  *) echo "unknown engine: $ENGINE" >&2; exit 1 ;;
esac

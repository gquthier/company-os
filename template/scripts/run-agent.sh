#!/usr/bin/env bash
{ # This group makes bash parse the whole file before running anything: an in-place edit during
  # a long run would otherwise shift the read offset (a real incident). Do not remove.
# run-agent.sh <agent> [--task "…"] [--engine claude|codex] [--model M] [--effort E] [--dry-run]
# One headless run of one agent: loads its role sheet + the OS reading order, executes its
# mission, guarantees a log line. Engine/models from .env (COMPANY_OS_*), overridable here.
set -euo pipefail
. "$(dirname "$0")/lib.sh"
AGENT="${1:-}"; shift || true
[ -n "$AGENT" ] || { echo "usage: run-agent.sh <agent> [--task …] [--engine claude|codex] [--model M] [--effort E] [--dry-run]" >&2; exit 1; }
require_agent "$AGENT"
ENGINE="${COMPANY_OS_ENGINE:-claude}"; TASK=""; DRY=0
MODEL="${COMPANY_OS_MODEL:-}"; EFFORT="${COMPANY_OS_EFFORT:-}"
CODEX_MODEL="${COMPANY_OS_CODEX_MODEL:-}"; CODEX_EFFORT="${COMPANY_OS_CODEX_EFFORT:-}"
while [ $# -gt 0 ]; do case "$1" in
  --task) TASK="$2"; shift 2;; --engine) ENGINE="$2"; shift 2;;
  --model) MODEL="$2"; CODEX_MODEL="$2"; shift 2;; --effort) EFFORT="$2"; CODEX_EFFORT="$2"; shift 2;;
  --dry-run) DRY=1; shift;; *) shift;; esac; done

# One run per agent at a time (pidfile), taken early.
PIDFILE="state/run-$AGENT.pid"; mkdir -p state
if [ -f "$PIDFILE" ] && kill -0 "$(cat "$PIDFILE" 2>/dev/null)" 2>/dev/null; then
  echo "⏳ run $AGENT already in progress (pid $(cat "$PIDFILE")) — skip"; exit 0; fi
echo $$ > "$PIDFILE"; trap 'rm -f "$PIDFILE"' EXIT INT TERM

DATE="$(today)"; TS="$(date +%FT%H-%M-%S)"
export COMPANY_OS_RUN_ID="${AGENT}-${TS}-$$"   # disambiguates two parallel instances (claims R8)
mkdir -p "logs/$AGENT" "reports/daily/$DATE" "bus/inbox/$AGENT/done"

read -r -d '' PROMPT <<EOF || true
You are the agent '$AGENT' of this Company OS (root: $COS_ROOT). Your role sheet: agents/$AGENT/AGENTS.md — read it first.
MANDATORY before acting, in this order: MISSION.md, COMPANY.md, RULES.md, ENVIRONMENT.md (binding rules: knowledge,
permissions, escalation), knowledge/KNOWLEDGE-MAP.md (lookup-first: find the existing truth before any decision),
policies/autonomy.md (T1/T2/T3), agents/TEAM.md (who to consult).
Steps for this run:
0. Read bus/DECISIONS.md (R9): the founder's decisions, live. A decision already taken is NEVER re-escalated.
   The founder gives you a decision during this run → scripts/decision.sh set "<subject>" "<decision>" DECIDED founder→$AGENT.
1. Read your inbox bus/inbox/$AGENT/ (handle, then archive each file to bus/inbox/$AGENT/done/).
2. Execute your mission. For every sub-task pick the tier with scripts/route-model.sh <class>.
   🔒 CLAIM FIRST (R8): for any substantial task, scripts/claim.sh take "<precise scope>" "$AGENT".
   Refused (exit 3) = a duplicate is already in progress → DO NOT START; coordinate via bus/inbox/chief-of-staff/.
   Otherwise advance the status: set <id> IN-PROGRESS, then REVIEW / SHIPPED, then DONE. Your run id: $COMPANY_OS_RUN_ID.
   Need another agent's expertise → scripts/consult.sh <agent> "question" (sync, opinion) or a file in
   bus/inbox/<agent>/ + scripts/notify-agent.sh <agent> (async task).
   Work in the execution plane (a repo, a tool) is always LOCATED and traced (E2); never here (E1).
3. Anything outside your autonomy tier → a message in bus/inbox/chief-of-staff/ + a PENDING row (decision.sh) + STOP.
4. P0 event ONLY → scripts/notify.sh "<message>". Everything else goes in your report.
5. End with one JSON line in logs/$AGENT/$DATE.jsonl via scripts/log.sh $AGENT run "<what you did, what you found, cost>"
   and, if this is a standup or a FIRST DAY run, write reports/daily/$DATE/$AGENT.md (done · found · waiting on the founder · cost).
Never print, log or commit a secret. Never answer from memory about the company: look it up.
${TASK:+Explicit task for this run: $TASK}
EOF

if [ "$DRY" = 1 ]; then echo "── DRY RUN · agent=$AGENT engine=$ENGINE model=${MODEL:-<default>} effort=${EFFORT:-<default>}"; printf '%s\n' "$PROMPT"; exit 0; fi

BYPASS_C=""; BYPASS_X=""
if [ "${COMPANY_OS_BYPASS_PERMISSIONS:-0}" = "1" ]; then BYPASS_C="--dangerously-skip-permissions"; BYPASS_X="--dangerously-bypass-approvals-and-sandbox"; fi
LIVE="logs/$AGENT/live.log"; OUT="logs/$AGENT/$TS.out"
{ echo ""; echo "════ ▶ $TS · $AGENT · $ENGINE ${MODEL:-}"; echo "TASK: ${TASK:-(default mission)}"; } >> "$LIVE"
echo "▶ run $AGENT via $ENGINE ${MODEL:+model=$MODEL }${EFFORT:+effort=$EFFORT }($TS)"
RC=0
case "$ENGINE" in
  claude)
    command -v claude >/dev/null || { echo "claude CLI not found on PATH" >&2; exit 127; }
    set +e; claude -p $BYPASS_C ${MODEL:+--model "$MODEL"} ${EFFORT:+--effort "$EFFORT"} "$PROMPT" 2>&1 | tee "$OUT" | tee -a "$LIVE"; RC=${PIPESTATUS[0]}; set -e ;;
  codex)
    command -v codex >/dev/null || { echo "codex CLI not found on PATH" >&2; exit 127; }
    set +e; codex exec $BYPASS_X ${CODEX_MODEL:+-c model="$CODEX_MODEL"} ${CODEX_EFFORT:+-c model_reasoning_effort="$CODEX_EFFORT"} "$PROMPT" 2>&1 | tee "$OUT" | tee -a "$LIVE"; RC=${PIPESTATUS[0]}; set -e ;;
  *) echo "unknown engine: $ENGINE (claude|codex)" >&2; exit 1 ;;
esac
# Minimal trace: the agent writes its rich line itself; this guarantees at least one record (R5).
printf '{"ts":"%s","agent":"%s","run":"%s","type":"run-end","engine":"%s","trigger":%s,"rc":%s}\n' \
  "$(now_iso)" "$AGENT" "$COMPANY_OS_RUN_ID" "$ENGINE" "$(json_str "${TASK:-scheduled}")" "$RC" >> "logs/$AGENT/$DATE.jsonl"
echo "✔ run $AGENT finished (rc=$RC) → logs/$AGENT/$DATE.jsonl"
exit "$RC"
}; exit $?

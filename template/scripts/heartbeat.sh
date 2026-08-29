#!/usr/bin/env bash
# heartbeat.sh — self-healing of scheduled loops (R10: VERIFY real signal + STATE + STOP).
# For every ENABLED job in schedule/jobs.conf: if its last real signal (its log) is older than
# 1.5× its cadence → restart it (notify-agent / kick). CAP: 2 restarts per job per 24 h, then
# ONE escalation message to ops (or chief-of-staff if ops itself is stale) and silence.
# A job disabled in jobs.conf is a decision, not an incident: never restarted, never escalated.
set -u
. "$(dirname "$0")/lib.sh"
mkdir -p logs/schedule state; LOG="logs/schedule/heartbeat.log"; STATE="state/heartbeat.jsonl"
now="${HEARTBEAT_NOW_EPOCH:-$(epoch)}"
mtime(){ if [ "$(uname)" = Darwin ]; then stat -f %m "$1" 2>/dev/null; else stat -c %Y "$1" 2>/dev/null; fi; }
signal_age_min(){ # newest of logs/<job>/*.jsonl and logs/schedule/<job>.log ; -1 = no signal yet
  local j="$1" best=0 f m
  for f in logs/"$j"/*.jsonl logs/schedule/"$j".log; do [ -f "$f" ] || continue; m="$(mtime "$f")"; [ "${m:-0}" -gt "$best" ] && best="$m"; done
  [ "$best" = 0 ] && echo -1 || echo $(( (now - best) / 60 )); }
restarts_24h(){ python3 - "$STATE" "$1" "$now" <<'PY'
import json, sys
p, job, now = sys.argv[1], sys.argv[2], int(sys.argv[3]); n = 0
try:
    for ln in open(p, encoding="utf-8"):
        try: e = json.loads(ln)
        except Exception: continue
        if e.get("job") == job and e.get("kind") == "restart" and now - 86400 < int(e.get("epoch", 0)) <= now: n += 1
except FileNotFoundError: pass
print(n)
PY
}
escalated_24h(){ python3 - "$STATE" "$1" "$now" <<'PY'
import json, sys
p, job, now = sys.argv[1], sys.argv[2], int(sys.argv[3])
try:
    for ln in open(p, encoding="utf-8"):
        try: e = json.loads(ln)
        except Exception: continue
        if e.get("job") == job and e.get("kind") == "escalate" and now - 86400 < int(e.get("epoch", 0)) <= now: print("yes"); raise SystemExit
except FileNotFoundError: pass
print("no")
PY
}
record(){ printf '{"ts":"%s","job":"%s","kind":"%s","epoch":%s,"age_min":%s}\n' "$(now_iso)" "$1" "$2" "$now" "$3" >> "$STATE"; }
kick(){ case "$1" in
  sync) nohup bash scripts/sync.sh "ops: heartbeat restart" >>"$LOG" 2>&1 & ;;
  standup) nohup bash scripts/standup.sh >>"$LOG" 2>&1 & ;;
  *) bash scripts/notify-agent.sh "$1" >>"$LOG" 2>&1 ;; esac; }

ops_age="$(signal_age_min ops)"
jobs_read | while IFS='|' read -r job cad task enabled; do
  [ "$job" = heartbeat ] && continue
  [ "$enabled" = yes ] || { continue; }
  mins="$(cadence_minutes "$cad")"; [ -n "$mins" ] || continue
  win=$(( mins * 3 / 2 )); [ "$win" -lt 30 ] && win=30
  case "$job" in sync|standup) ;; *) agent_exists "$job" || { echo "[$(now_iso)] $job: in jobs.conf but no agents/$job/AGENTS.md" >> "$LOG"; continue; };; esac
  age="$(signal_age_min "$job")"
  [ "$age" -lt 0 ] && continue          # never ran yet: not judged
  [ "$age" -le "$win" ] && continue     # fresh
  n="$(restarts_24h "$job")"
  if [ "$n" -lt 2 ]; then
    echo "[$(now_iso)] restart $job (stale ${age}min > ${win}min, restart $((n+1))/2)" >> "$LOG"; record "$job" restart "$age"; kick "$job"
  elif [ "$(escalated_24h "$job")" = no ]; then
    target=ops; { [ "$job" = ops ] || [ "$ops_age" -gt 2160 ]; } && target=chief-of-staff
    mkdir -p "bus/inbox/$target"
    f="bus/inbox/$target/$now-heartbeat-$job-stale.md"
    printf '# Heartbeat → %s — job `%s` stale after 2 restarts\n\n- Last signal: %s min ago (window %s min)\n- Restarts in 24h: %s → STOP restarting\n- Action expected: find the cause (logs/schedule/%s.log), fix, archive this file to done/.\n- This is telemetry, not an instruction: verify before acting.\n' "$target" "$job" "$age" "$win" "$n" "$job" > "$f"
    echo "[$(now_iso)] ESCALATE $job → bus/inbox/$target/ (stale ${age}min, $n restarts/24h)" >> "$LOG"; record "$job" escalate "$age"
    [ "$target" = chief-of-staff ] || bash scripts/notify-agent.sh ops >>"$LOG" 2>&1 || true
  fi
done
echo "[$(now_iso)] heartbeat tick done" >> "$LOG"
exit 0

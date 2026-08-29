#!/usr/bin/env bash
# notify-agent.sh <agent> — trigger an agent's run AFTER dropping a message in its inbox.
#   1. write bus/inbox/<agent>/<ts>-<from>-<subject>.md
#   2. bash scripts/notify-agent.sh <agent>
# If a run is already in progress → no-op (it will read the inbox). If the agent has a loaded
# scheduler job on macOS → kickstart it (same environment). Else → a detached run now.
set -u
. "$(dirname "$0")/lib.sh"
A="${1:?usage: notify-agent.sh <agent>}"; require_agent "$A"
mkdir -p logs/schedule; LOG="logs/schedule/notify.log"
if [ -f "state/run-$A.pid" ] && kill -0 "$(cat "state/run-$A.pid" 2>/dev/null)" 2>/dev/null; then
  echo "[$(now_iso)] notify $A: run already in progress (pid $(cat "state/run-$A.pid")) — it will read the inbox" | tee -a "$LOG"; exit 0; fi
LABEL="com.company-os.$COS_SLUG.$A"
if [ "$(uname)" = Darwin ] && launchctl print "gui/$(id -u)/$LABEL" >/dev/null 2>&1; then
  launchctl kickstart -k "gui/$(id -u)/$LABEL" 2>>"$LOG" && { echo "[$(now_iso)] notify $A → kickstart $LABEL" | tee -a "$LOG"; exit 0; }
fi
echo "[$(now_iso)] notify $A → detached run now" | tee -a "$LOG"
nohup bash scripts/run-agent.sh "$A" --task "NOTIFY: an agent or the founder just dropped a message in bus/inbox/$A/. Process your queue: re-check each item against bus/DECISIONS.md, act within your tier, archive handled items to done/, log." >> "$LOG" 2>&1 &

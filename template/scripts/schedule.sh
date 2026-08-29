#!/usr/bin/env bash
# schedule.sh install|uninstall|list|kick <job> — the scheduler, generated from schedule/jobs.conf.
# macOS → launchd plists in ~/Library/LaunchAgents/com.company-os.<slug>.<job>.plist
# Linux → a marked block in the user's crontab. Idempotent: re-run after editing jobs.conf.
set -euo pipefail
. "$(dirname "$0")/lib.sh"
CMD="${1:-list}"; shift || true
OS="$(uname)"; UID_="$(id -u)"; LA="$HOME/Library/LaunchAgents"
PATH_FOR_JOBS="$(dirname "$(command -v claude 2>/dev/null || command -v codex 2>/dev/null || echo /usr/local/bin/x)"):$HOME/.local/bin:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin"
label(){ echo "com.company-os.$COS_SLUG.$1"; }
script_for(){ case "$1" in
  heartbeat) echo "scripts/heartbeat.sh";; sync) echo "scripts/sync.sh";; standup) echo "scripts/standup.sh";;
  *) echo "scripts/run-agent.sh";; esac; }
args_for(){ case "$1" in heartbeat|sync|standup) echo "";; *) echo "$1";; esac; }

plist_write(){ # job cadence task
  local job="$1" cad="$2" task="$3" f="$LA/$(label "$job").plist" sched
  case "$cad" in
    every:*) sched="<key>StartInterval</key><integer>$(( $(cadence_minutes "$cad") * 60 ))</integer>";;
    daily:*) h="${cad#daily:}"; sched="<key>StartCalendarInterval</key><dict><key>Hour</key><integer>$((10#${h%%:*}))</integer><key>Minute</key><integer>$((10#${h##*:}))</integer></dict>";;
    weekly:*) d="${cad#weekly:}"; wd="${d%%:*}"; h="${d#*:}"
      case "$wd" in sun) n=0;; mon) n=1;; tue) n=2;; wed) n=3;; thu) n=4;; fri) n=5;; sat) n=6;; *) n=1;; esac
      sched="<key>StartCalendarInterval</key><dict><key>Weekday</key><integer>$n</integer><key>Hour</key><integer>$((10#${h%%:*}))</integer><key>Minute</key><integer>$((10#${h##*:}))</integer></dict>";;
    *) say "unknown cadence '$cad' for $job — skipped"; return 0;;
  esac
  local taskxml=""; [ -n "$task" ] && taskxml="<string>--task</string><string>$(python3 -c 'import html,sys;print(html.escape(sys.argv[1]))' "$task")</string>"
  local argxml=""; [ -n "$(args_for "$job")" ] && argxml="<string>$(args_for "$job")</string>"
  cat > "$f" <<EOT
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>Label</key><string>$(label "$job")</string>
  <key>ProgramArguments</key><array><string>/bin/bash</string><string>$COS_ROOT/$(script_for "$job")</string>$argxml$taskxml</array>
  <key>WorkingDirectory</key><string>$COS_ROOT</string>
  $sched
  <key>AbandonProcessGroup</key><true/>
  <key>ProcessType</key><string>Background</string>
  <key>StandardOutPath</key><string>$COS_ROOT/logs/schedule/$job.log</string>
  <key>StandardErrorPath</key><string>$COS_ROOT/logs/schedule/$job.log</string>
  <key>EnvironmentVariables</key><dict><key>PATH</key><string>$PATH_FOR_JOBS</string><key>HOME</key><string>$HOME</string></dict>
</dict></plist>
EOT
  chmod 644 "$f"
  launchctl bootout "gui/$UID_" "$f" >/dev/null 2>&1 || true
  launchctl enable "gui/$UID_/$(label "$job")" >/dev/null 2>&1 || true
  launchctl bootstrap "gui/$UID_" "$f" >/dev/null 2>&1 || launchctl load "$f" >/dev/null 2>&1 || { say "could not load $(label "$job")"; return 0; }
  echo "  ✅ $(label "$job")  $cad"
}
cron_line(){ # job cadence task → crontab line
  local job="$1" cad="$2" task="$3" spec cmd
  case "$cad" in
    every:*m) spec="*/$(cadence_minutes "$cad") * * * *";;
    every:*h) spec="0 */$(( $(cadence_minutes "$cad") / 60 )) * * *";;
    daily:*) h="${cad#daily:}"; spec="$((10#${h##*:})) $((10#${h%%:*})) * * *";;
    weekly:*) d="${cad#weekly:}"; wd="${d%%:*}"; h="${d#*:}"; spec="$((10#${h##*:})) $((10#${h%%:*})) * * ${wd:0:3}";;
    *) return 0;;
  esac
  cmd="cd $COS_ROOT && PATH=$PATH_FOR_JOBS /bin/bash $(script_for "$job") $(args_for "$job")"
  [ -n "$task" ] && cmd="$cmd --task '$(printf '%s' "$task" | sed "s/'/'\\\\''/g")'"
  echo "$spec $cmd >> $COS_ROOT/logs/schedule/$job.log 2>&1"
}

mkdir -p logs/schedule
case "$CMD" in
  install)
    echo "SCHEDULE · $COS_SLUG · $COS_ROOT"
    [ "${COMPANY_OS_BYPASS_PERMISSIONS:-0}" = "1" ] || echo "  ⚠️  COMPANY_OS_BYPASS_PERMISSIONS is not 1 in .env — unattended agent runs will not be able to act (see docs/TROUBLESHOOTING.md)"
    if [ "$OS" = Darwin ]; then
      mkdir -p "$LA"
      # remove jobs no longer in jobs.conf or disabled
      for f in "$LA"/com.company-os."$COS_SLUG".*.plist; do [ -f "$f" ] || continue; j="$(basename "$f" .plist)"; j="${j#com.company-os.$COS_SLUG.}"
        if ! jobs_read | grep -qE "^$j\|.*\|yes$"; then launchctl bootout "gui/$UID_" "$f" >/dev/null 2>&1 || true; rm -f "$f"; echo "  🗑  $(label "$j") removed"; fi; done
      jobs_read | while IFS='|' read -r job cad task en; do [ "$en" = yes ] || { echo "  ⏸  $job disabled (jobs.conf)"; continue; }; plist_write "$job" "$cad" "$task"; done
    else
      BLOCK="$( jobs_read | while IFS='|' read -r job cad task en; do [ "$en" = yes ] && cron_line "$job" "$cad" "$task"; done )"
      { crontab -l 2>/dev/null | sed "/# company-os:$COS_SLUG:start/,/# company-os:$COS_SLUG:end/d"; echo "# company-os:$COS_SLUG:start"; echo "$BLOCK"; echo "# company-os:$COS_SLUG:end"; } | crontab -
      echo "$BLOCK" | sed 's/^/  ✅ /'
    fi ;;
  uninstall)
    if [ "$OS" = Darwin ]; then for f in "$LA"/com.company-os."$COS_SLUG".*.plist; do [ -f "$f" ] || continue; launchctl bootout "gui/$UID_" "$f" >/dev/null 2>&1 || true; rm -f "$f"; echo "  🗑  $(basename "$f")"; done
    else crontab -l 2>/dev/null | sed "/# company-os:$COS_SLUG:start/,/# company-os:$COS_SLUG:end/d" | crontab -; echo "  🗑  crontab block removed"; fi ;;
  list)
    echo "jobs.conf:"; jobs_read | sed 's/^/  /'
    if [ "$OS" = Darwin ]; then echo "loaded (launchd):"; launchctl list 2>/dev/null | grep "com.company-os.$COS_SLUG" | awk '{print "  " $3 "  (pid " $1 ", last rc " $2 ")"}' || echo "  none"
    else echo "crontab:"; crontab -l 2>/dev/null | sed -n "/# company-os:$COS_SLUG:start/,/# company-os:$COS_SLUG:end/p" | sed 's/^/  /'; fi ;;
  kick)
    J="${1:?usage: kick <job>}"
    if [ "$OS" = Darwin ] && launchctl print "gui/$UID_/$(label "$J")" >/dev/null 2>&1; then launchctl kickstart -k "gui/$UID_/$(label "$J")" && echo "kicked $(label "$J")"
    else case "$J" in heartbeat|sync|standup) bash "$(script_for "$J")";; *) bash scripts/run-agent.sh "$J";; esac; fi ;;
  *) echo "usage: schedule.sh install|uninstall|list|kick <job>" >&2; exit 1 ;;
esac

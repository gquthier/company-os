#!/usr/bin/env bash
# notify.sh "<message>" — P0 notification to the founder (RULES R5: P0 ONLY).
# Transport, in order: NOTIFY_WEBHOOK_URL (Slack / Discord incoming webhook) · Telegram bot ·
# fallback = print + logs/notify.log. Never fails the caller.
set -uo pipefail
. "$(dirname "$0")/lib.sh"
MSG="${1:-}"; [ -n "$MSG" ] || { echo "usage: notify.sh \"message\"" >&2; exit 1; }
mkdir -p logs; echo "[$(now_iso)] $MSG" >> logs/notify.log
sent=0
if [ -n "${NOTIFY_WEBHOOK_URL:-}" ]; then
  case "$NOTIFY_WEBHOOK_URL" in *discord.com*|*discordapp.com*) KEY=content;; *) KEY=text;; esac
  BODY="$(python3 -c 'import json,sys;print(json.dumps({sys.argv[1]:sys.argv[2]}))' "$KEY" "$MSG")"
  curl -sS --connect-timeout 5 --max-time 10 -X POST -H 'Content-Type: application/json' --data "$BODY" "$NOTIFY_WEBHOOK_URL" >/dev/null 2>&1 && sent=1
fi
if [ "$sent" = 0 ] && [ -n "${NOTIFY_TELEGRAM_BOT_TOKEN:-}" ] && [ -n "${NOTIFY_TELEGRAM_CHAT_ID:-}" ]; then
  curl -sS --connect-timeout 5 --max-time 10 -X POST "https://api.telegram.org/bot${NOTIFY_TELEGRAM_BOT_TOKEN}/sendMessage" \
    --data-urlencode "chat_id=${NOTIFY_TELEGRAM_CHAT_ID}" --data-urlencode "text=${MSG}" >/dev/null 2>&1 && sent=1
fi
if [ "$sent" = 1 ]; then echo "✔ notified"; else echo "⚠️  no notification channel configured (.env) — logged only: $MSG"; fi
exit 0

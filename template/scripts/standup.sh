#!/usr/bin/env bash
# standup.sh — every agent writes its daily report, then the chief of staff writes the digest.
set -euo pipefail
. "$(dirname "$0")/lib.sh"
DATE="$(today)"; mkdir -p "reports/daily/$DATE"
for a in $(agents_list); do
  case "$a" in chief-of-staff|reviewer) continue;; esac
  echo "→ daily report: $a"
  bash scripts/run-agent.sh "$a" --task "STANDUP: write your report of the day in reports/daily/$DATE/$a.md (done · found · waiting on the founder · cost). If a founder decision is needed, drop a message in bus/inbox/chief-of-staff/ and a PENDING row via decision.sh." "$@" || echo "  ⚠️  $a failed (rc=$?) — listed in the digest"
done
echo "→ chief of staff: digest"
bash scripts/run-agent.sh chief-of-staff --task "STANDUP: read reports/daily/$DATE/*.md and every bus/inbox/*/ (items older than 24h = relaunch or reassign), then write reports/daily/$DATE/chief-of-staff.md in the investor digest format of your role sheet. Missing reports are listed. Notify ONLY if a P0 is open." "$@"
echo "✔ standup → reports/daily/$DATE/chief-of-staff.md"

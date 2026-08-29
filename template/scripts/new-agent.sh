#!/usr/bin/env bash
# new-agent.sh <slug> "<role in one line>" — scaffold a new agent from agents/_template.
# Creates agents/<slug>/{AGENTS.md,CLAUDE.md}, bus/inbox/<slug>/done, logs/<slug>, and a roster
# row in agents/TEAM.md. Then YOU: rewrite AGENTS.md (docs/AGENTS-CATALOG.md), RULES.md R2,
# policies/autonomy.md, connectors, schedule/jobs.conf. Run it once by hand before scheduling.
set -euo pipefail
. "$(dirname "$0")/lib.sh"
SLUG="${1:?usage: new-agent.sh <slug> \"<role>\"}"; ROLE="${2:?role required}"
echo "$SLUG" | grep -qE '^[a-z][a-z0-9-]{1,30}$' || { echo "slug must be lowercase letters, digits, dashes" >&2; exit 1; }
[ -d "agents/$SLUG" ] && { echo "agents/$SLUG already exists" >&2; exit 1; }
mkdir -p "agents/$SLUG" "bus/inbox/$SLUG/done" "logs/$SLUG"
for f in AGENTS.md CLAUDE.md; do sed -e "s/{{AGENT}}/$SLUG/g" -e "s/{{ROLE}}/$(printf '%s' "$ROLE" | sed 's/[&/\]/\\&/g')/g" "agents/_template/$f" > "agents/$SLUG/$f"; done
touch "bus/inbox/$SLUG/.gitkeep" "bus/inbox/$SLUG/done/.gitkeep"
ROW="| **$SLUG** | $ROLE | TODO: when to consult it | \`bus/inbox/$SLUG/\` |"
if grep -q '<!-- roster:end -->' agents/TEAM.md; then
  python3 - agents/TEAM.md "$ROW" <<'PY'
import sys
p, row = sys.argv[1], sys.argv[2]; s = open(p, encoding="utf-8").read()
open(p, "w", encoding="utf-8").write(s.replace("<!-- roster:end -->", row + "\n<!-- roster:end -->", 1))
PY
else echo "$ROW" >> agents/TEAM.md; fi
cat <<EOT
✅ agent '$SLUG' created
  agents/$SLUG/AGENTS.md      ← rewrite from docs/AGENTS-CATALOG.md (identity · mission · autonomy · cadence · models · report)
  agents/TEAM.md              ← roster row added; fill "when to consult it"
  RULES.md R2                 ← add its allowed / forbidden row
  policies/autonomy.md        ← map its actions to T1/T2/T3
  connectors/README.md        ← the systems it reads (variable names only)
  schedule/jobs.conf          ← add it only after: bash scripts/run-agent.sh $SLUG --task "first run"
EOT

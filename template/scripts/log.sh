#!/usr/bin/env bash
# log.sh <agent> <type> "<summary>" [cost] [extra-json-object]
# Appends one JSON line to logs/<agent>/<date>.jsonl. RULES R5: no log = the run did not exist.
# Types: run · consult · decision · escalation · task · error (free text, kept short).
set -euo pipefail
. "$(dirname "$0")/lib.sh"
AGENT="${1:?usage: log.sh <agent> <type> \"<summary>\" [cost] [extra-json]}"; TYPE="${2:?type}"; SUMMARY="${3:?summary}"
COST="${4:-}"; EXTRA="${5:-{\}}"
require_agent "$AGENT"
mkdir -p "logs/$AGENT"
python3 - "$AGENT" "$TYPE" "$SUMMARY" "$COST" "$EXTRA" "${COMPANY_OS_RUN_ID:-manual}" "logs/$AGENT/$(today).jsonl" <<'PY'
import json, sys, datetime
agent, typ, summary, cost, extra, run, path = sys.argv[1:8]
rec = {"ts": datetime.datetime.now().astimezone().isoformat(timespec="seconds"), "agent": agent, "run": run, "type": typ, "summary": summary}
if cost: rec["cost"] = cost
try:
    e = json.loads(extra) if extra else {}
    if isinstance(e, dict): rec.update(e)
except Exception: rec["extra"] = extra
open(path, "a", encoding="utf-8").write(json.dumps(rec, ensure_ascii=False) + "\n")
print(f"logged → {path}")
PY

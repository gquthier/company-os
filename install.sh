#!/usr/bin/env bash
# install.sh — copy the Company OS template into its own folder and initialise it.
# Usage: bash install.sh [target-dir] [--slug <company-slug>] [--force]
#   target-dir  default ~/company-os
#   --slug      short identifier used for scheduler labels (default: folder name)
#   --force     allow a non-empty target (files are never overwritten unless --force)
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
TEMPLATE="$HERE/template"
[ -d "$TEMPLATE" ] || { echo "install: template/ not found next to install.sh" >&2; exit 1; }

TARGET="$HOME/company-os"; SLUG=""; FORCE=0
while [ $# -gt 0 ]; do case "$1" in
  --slug) SLUG="$2"; shift 2;;
  --force) FORCE=1; shift;;
  -h|--help) sed -n '2,7p' "$0"; exit 0;;
  *) TARGET="$1"; shift;;
esac; done
TARGET="${TARGET/#\~/$HOME}"
[ -n "$SLUG" ] || SLUG="$(basename "$TARGET" | tr -c 'A-Za-z0-9-\n' '-' | tr 'A-Z' 'a-z')"

if [ -d "$TARGET" ] && [ -n "$(ls -A "$TARGET" 2>/dev/null)" ] && [ "$FORCE" -ne 1 ]; then
  echo "install: $TARGET exists and is not empty — pass --force to copy into it (existing files are kept)" >&2
  exit 1
fi
mkdir -p "$TARGET"

# copy without overwriting (rsync if present, cp -n otherwise)
if command -v rsync >/dev/null 2>&1; then
  rsync -a --ignore-existing "$TEMPLATE"/ "$TARGET"/
else
  (cd "$TEMPLATE" && find . -type d -exec mkdir -p "$TARGET/{}" \; && find . -type f -exec sh -c 'for f; do [ -e "$0/$f" ] || cp "$f" "$0/$f"; done' "$TARGET" {} +)
fi
chmod +x "$TARGET"/scripts/*.sh "$TARGET"/tests/*.sh 2>/dev/null || true
[ -f "$TARGET/.env" ] || cp "$TARGET/.env.example" "$TARGET/.env"
grep -q '^COMPANY_OS_SLUG=' "$TARGET/.env" 2>/dev/null \
  && sed -i.bak "s|^COMPANY_OS_SLUG=.*|COMPANY_OS_SLUG=$SLUG|" "$TARGET/.env" && rm -f "$TARGET/.env.bak" \
  || printf '\nCOMPANY_OS_SLUG=%s\n' "$SLUG" >> "$TARGET/.env"

cd "$TARGET"
if [ ! -d .git ]; then
  git init -q -b main 2>/dev/null || git init -q
  git add -A
  git -c user.name="${GIT_AUTHOR_NAME:-company-os}" -c user.email="${GIT_AUTHOR_EMAIL:-company-os@localhost}" \
    commit -q -m "company-os: template installed" >/dev/null 2>&1 || true
fi

cat <<EOT

✅ Company OS installed in $TARGET  (slug: $SLUG)

Next:
  cd "$TARGET"
  claude                      # or: codex
  > Read SKILL.md in the template repo and set up my Company OS   (one question)
  — or fill COMPANY.md and MISSION.md yourself, then:
  bash scripts/doctor.sh
  bash scripts/run-agent.sh chief-of-staff --task "FIRST DAY: read everything and report"

Secrets go in $TARGET/.env only (gitignored). Add a PRIVATE remote before running on several machines:
  git remote add origin <your-private-repo-url> && bash scripts/sync.sh "first push"
EOT

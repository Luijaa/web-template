#!/usr/bin/env bash
# Run once in a NEW repo created from this template: fills the {{...}} placeholders,
# drops <!-- template-only --> blocks, then deletes itself (the new repo does not need it).
# usage: scripts/init-project.sh <project-name> ["one line description"] [dev-url] ["who uses it"] [github-org]
# github-org defaults to the owner in `git remote get-url origin` (GHCR image: ghcr.io/<org>/<name>).
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"

name="${1:?usage: scripts/init-project.sh <project-name> [description] [dev-url] [users] [github-org]}"
# the name becomes the GHCR image name and the compose project name: lowercase letters, digits and '-' only
if ! printf '%s' "$name" | grep -Eq '^[a-z0-9][a-z0-9-]*$'; then
  echo "project name '$name' must match ^[a-z0-9][a-z0-9-]*\$ (lowercase, digits, '-'), same as the repo name" >&2; exit 1
fi
desc="${2:-TODO: one line description}"
url="${3:-https://dev-${name}.example.com}"
users="${4:-TODO: who uses it}"
org="${5:-}"
if [ -z "$org" ]; then
  remote=$(git remote get-url origin 2>/dev/null || true)
  org=$(printf '%s' "$remote" | sed -nE 's#^(https://([^@/]+@)?github\.com/|git@github\.com:)([^/]+)/.*#\3#p')
fi
[ -n "$org" ] || { echo "cannot tell the GitHub org from 'origin' — pass it as the 5th argument" >&2; exit 1; }
org=$(printf '%s' "$org" | tr '[:upper:]' '[:lower:]')   # GHCR image names must be lowercase

files=$(grep -rIl '{{[A-Z_]*}}' --exclude-dir=.git --exclude-dir=scripts . || true)
[ -z "$files" ] && { echo "no placeholders left"; exit 0; }

for f in $files; do
  NAME="$name" DESC="$desc" URL="$url" USERS="$users" ORG="$org" python3 - "$f" <<'PY'
import os, re, sys
p = sys.argv[1]
s = open(p, encoding="utf-8").read()
s = re.sub(r"\n?<!-- template-only:start -->.*?<!-- template-only:end -->\n?", "\n", s, flags=re.S)
s = (s.replace("{{PROJECT_NAME}}", os.environ["NAME"])
      .replace("{{ONE_LINE_DESCRIPTION}}", os.environ["DESC"])
      .replace("{{DEV_URL}}", os.environ["URL"])
      .replace("{{USERS}}", os.environ["USERS"])
      .replace("{{GITHUB_ORG}}", os.environ["ORG"]))
open(p, "w", encoding="utf-8").write(s)
PY
  echo "  filled $f"
done

# one-shot: remove this script so the new repo does not carry template tooling
self="scripts/init-project.sh"
git rm -q --ignore-unmatch "$self" 2>/dev/null || true
rm -f "$self"
echo "  removed $self"
echo "now review AGENTS.md / README.md, then: git add -A && git commit -m 'chore: init from web-template'"

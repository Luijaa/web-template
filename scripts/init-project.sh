#!/usr/bin/env bash
# Run once in a NEW repo created from this template: fills the {{...}} placeholders,
# drops <!-- template-only --> blocks, then deletes itself (the new repo does not need it).
# usage: scripts/init-project.sh --runner github|self-hosted <project-name> ["one line description"] [dev-url] ["who uses it"] [github-org]
# github-org defaults to the owner in `git remote get-url origin` (GHCR image: ghcr.io/<org>/<name>).
# --runner (asked when missing and run in a terminal) — where CI runs, docs/testing.md "CI runners":
#   github       GitHub-hosted ubuntu-24.04 / ubuntu-24.04-arm (public or private repo)
#   self-hosted  your runners picked by label [self-hosted, Linux, X64] and [self-hosted, Linux, ARM64]
#                (needs both; private repo only — on a public repo a fork's PR runs code on your machine)
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"

usage="usage: scripts/init-project.sh --runner github|self-hosted <project-name> [description] [dev-url] [users] [github-org]"
runner=""
pos=()
while [ $# -gt 0 ]; do
  case "$1" in
    --runner) runner="${2:-}"; shift 2 || { echo "$usage" >&2; exit 1; } ;;
    --runner=*) runner="${1#--runner=}"; shift ;;
    *) pos+=("$1"); shift ;;
  esac
done
set -- ${pos[@]+"${pos[@]}"}

if [ -z "$runner" ] && [ -t 0 ]; then
  echo "CI runs on? (docs/testing.md \"CI runners\")"
  echo "  1) github       GitHub-hosted runners (ubuntu-24.04 + ubuntu-24.04-arm)"
  echo "  2) self-hosted  your runners: labels [self-hosted, Linux, X64] + [self-hosted, Linux, ARM64], private repo only"
  read -r -p "choose 1 or 2: " choice
  case "$choice" in 1|github) runner=github ;; 2|self-hosted) runner=self-hosted ;; esac
fi
case "$runner" in
  github|self-hosted) ;;
  *) echo "choose where CI runs: --runner github or --runner self-hosted" >&2; echo "$usage" >&2; exit 1 ;;
esac

name="${1:?$usage}"
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

# self-hosted runners must never serve a public repo (a fork's pull_request would run on your machine)
if [ "$runner" = self-hosted ]; then
  if command -v gh > /dev/null 2>&1 && vis=$(gh repo view --json visibility -q .visibility 2>/dev/null); then
    if [ "$vis" = PUBLIC ]; then
      echo "this repo is public — self-hosted runners are for private repos only; use --runner github" >&2; exit 1
    fi
  else
    echo "  note: could not check the repo visibility (gh) — self-hosted runners only on a PRIVATE repo"
  fi
fi

# CI runners: rewrite runs-on in .github/workflows (markers `# runner: x64|arm64`) and fill {{CI_RUNNERS}}
RUNNER="$runner" python3 - <<'PY'
import glob, os, re
selfhosted = os.environ["RUNNER"] == "self-hosted"
labels = {"x64": "[self-hosted, Linux, X64]", "arm64": "[self-hosted, Linux, ARM64]"}
for p in glob.glob(".github/workflows/*.yml"):
    s = open(p, encoding="utf-8").read()
    if selfhosted:
        t = re.sub(r"runs-on: ubuntu-24\.04 # runner: (x64|arm64)", lambda m: "runs-on: " + labels[m.group(1)], s)
        t = t.replace("runner: ubuntu-24.04-arm }", "runner: " + labels["arm64"] + " }")
        t = t.replace("runner: ubuntu-24.04 }", "runner: " + labels["x64"] + " }")
    else:
        t = re.sub(r"(runs-on: ubuntu-24\.04) # runner: (x64|arm64)", r"\1", s)
    if t != s:
        open(p, "w", encoding="utf-8").write(t)
        print(f"  runners ({os.environ['RUNNER']}) {p}")
PY
if [ "$runner" = self-hosted ]; then
  ci_runners='self-hosted — `[self-hosted, Linux, X64]` และ `[self-hosted, Linux, ARM64]` (repo ต้องเป็น private)'
else
  ci_runners='GitHub-hosted — `ubuntu-24.04` และ `ubuntu-24.04-arm`'
fi

files=$(grep -rIl '{{[A-Z_]*}}' --exclude-dir=.git --exclude-dir=scripts . || true)
[ -z "$files" ] && { echo "no placeholders left"; exit 0; }

for f in $files; do
  NAME="$name" DESC="$desc" URL="$url" USERS="$users" ORG="$org" CI_RUNNERS="$ci_runners" python3 - "$f" <<'PY'
import os, re, sys
p = sys.argv[1]
s = open(p, encoding="utf-8").read()
s = re.sub(r"\n?<!-- template-only:start -->.*?<!-- template-only:end -->\n?", "\n", s, flags=re.S)
s = (s.replace("{{PROJECT_NAME}}", os.environ["NAME"])
      .replace("{{ONE_LINE_DESCRIPTION}}", os.environ["DESC"])
      .replace("{{DEV_URL}}", os.environ["URL"])
      .replace("{{USERS}}", os.environ["USERS"])
      .replace("{{GITHUB_ORG}}", os.environ["ORG"])
      .replace("{{CI_RUNNERS}}", os.environ["CI_RUNNERS"]))
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

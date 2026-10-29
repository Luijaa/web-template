#!/usr/bin/env bash
# PR size against the slice-size rule (docs/design-process.md section 4): added lines of non-test code
# compared with the merge base, committed + uncommitted + untracked — run it while working, not only at the end.
# usage: scripts/pr-size.sh [--base <ref>] [--limit <n>] [--warn]
#   --base   branch to compare with (default origin/main, else main)
#   --limit  threshold (default $PR_SIZE_LIMIT or 800)
#   --warn   never fail; print a GitHub warning when over the limit (CI)
# Not counted: tests, e2e, generated code, lockfiles, translation files, docs and agent files.
set -euo pipefail

base="" limit="${PR_SIZE_LIMIT:-800}" warn=false
while [ $# -gt 0 ]; do
  case "$1" in
    --base) base="$2"; shift 2 ;;
    --limit) limit="$2"; shift 2 ;;
    --warn) warn=true; shift ;;
    *) echo "usage: $0 [--base <ref>] [--limit <n>] [--warn]" >&2; exit 2 ;;
  esac
done
if [ -z "$base" ]; then
  if git rev-parse -q --verify origin/main >/dev/null; then base=origin/main; else base=main; fi
fi
mb=$(git merge-base "$base" HEAD)

# keep in sync with docs/design-process.md section 4
excludes=(
  ':(exclude,glob)**/*_test.go' ':(exclude,glob)**/testdata/**'
  ':(exclude,glob)**/*.spec.ts' ':(exclude,glob)**/*.test.ts' ':(exclude,glob)e2e/**'
  ':(exclude,glob)**/*_templ.go' ':(exclude,glob)**/*.gen.*'
  ':(exclude,glob)**/go.sum' ':(exclude,glob)**/*.lock' ':(exclude,glob)**/*.lockb'
  ':(exclude,glob)**/package-lock.json' ':(exclude,glob)**/pnpm-lock.yaml'
  ':(exclude,glob)**/locales/**'
  ':(exclude,glob)**/*.md' ':(exclude,glob)docs/**' ':(exclude,glob).agents/**' ':(exclude,glob).claude/**'
)

counted=$(mktemp)
trap 'rm -f "$counted"' EXIT
# tracked changes since the merge base (binary files report "-" and are skipped)
git diff --numstat "$mb" -- . "${excludes[@]}" | awk '$1 != "-" && $1 > 0 {print $1 "\t" $3}' >> "$counted"
# new files not yet added
git ls-files -z --others --exclude-standard -- . "${excludes[@]}" | while IFS= read -r -d '' f; do
  if grep -Iq . "$f" 2>/dev/null; then printf '%s\t%s\n' "$(wc -l < "$f" | tr -d ' ')" "$f"; fi
done >> "$counted"

total=$(awk '{s += $1} END {print s + 0}' "$counted")
all=$(git diff --numstat "$mb" | awk '$1 != "-" {s += $1} END {print s + 0}')

echo "pr-size: ${total} non-test lines added vs $(git rev-parse --short "$mb") (${base}); limit ~${limit}; all tracked files ${all}"
sort -rn "$counted" | head -10 | awk -F'\t' '{printf "  %6d  %s\n", $1, $2}'

if [ "$total" -gt "$limit" ]; then
  msg="PR size ${total} > ~${limit} non-test lines — split it (docs/design-process.md section 4)"
  if $warn; then echo "::warning::${msg}"; exit 0; fi
  echo "$msg" >&2
  exit 1
fi

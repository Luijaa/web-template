#!/usr/bin/env bash
# PostToolUse hook: format the file Claude just edited/wrote.
# Reads the hook JSON on stdin (tool_input.file_path, always absolute).
# Missing formatters are skipped silently; a formatter error is reported back to Claude (exit 2).
set -u

input=$(cat)
if command -v jq >/dev/null 2>&1; then
  file=$(printf '%s' "$input" | jq -r '.tool_input.file_path // empty')
else
  file=$(printf '%s' "$input" | python3 -c 'import sys,json; print(json.load(sys.stdin).get("tool_input",{}).get("file_path",""))' 2>/dev/null)
fi

[ -n "${file:-}" ] && [ -f "$file" ] || exit 0
case "$file" in */node_modules/*|*/.git/*|*/dist/*|*/build/*|*/.venv/*) exit 0 ;; esac

have() { command -v "$1" >/dev/null 2>&1; }
# set by Claude Code for hooks; fall back to the repo root when the script is run by hand or another tool
root="${CLAUDE_PROJECT_DIR:-$(git -C "$(dirname "$file")" rev-parse --show-toplevel 2>/dev/null || pwd)}"

run() {
  if ! out=$("$@" 2>&1); then
    echo "format failed for $file: $out" >&2
    exit 2
  fi
}

case "$file" in
  *.js|*.jsx|*.ts|*.tsx|*.mjs|*.cjs|*.css|*.scss|*.html|*.vue|*.svelte|*.json|*.yml|*.yaml|*.md)
    # project-local prettier only (never download on the fly)
    if [ -x "$root/web/node_modules/.bin/prettier" ]; then
      run "$root/web/node_modules/.bin/prettier" --write "$file"
    elif [ -x "$root/node_modules/.bin/prettier" ]; then
      run "$root/node_modules/.bin/prettier" --write "$file"
    fi ;;
  *.py)
    if have ruff; then run ruff format -q "$file"; fi ;;
  *.go)
    if have gofmt; then run gofmt -w "$file"; fi ;;
  *.sh)
    if have shfmt; then run shfmt -w -i 2 "$file"; fi ;;
esac
exit 0

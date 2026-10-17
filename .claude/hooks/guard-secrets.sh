#!/usr/bin/env bash
# PreToolUse hook (Bash): block shell commands that read real .env files or dump the environment.
# `Read(./.env…)` deny rules cover Claude's Read/Grep/Glob tools, but not `cat .env`, `grep x .env`,
# `set`, `export -p` … run through Bash — this closes that gap. `.env.example` stays allowed.
# Exit 2 = block the call and tell Claude why (stderr). Needs python3; without it the hook allows.
set -u
command -v python3 >/dev/null 2>&1 || exit 0

python3 -I -c '
import json, re, shlex, sys

try:
    cmd = json.load(sys.stdin).get("tool_input", {}).get("command", "") or ""
except Exception:
    sys.exit(0)

# 1. real .env files: any path whose last part is .env or .env.<x>, except .env.example
for tok in re.findall(r"[\w./~*?\[\]-]*\.env(?:\.[\w*?.-]+)?(?![\w.-])", cmd):
    base = tok.rsplit("/", 1)[-1]
    if base != ".env.example":
        print(f"blocked: command touches {tok!r} — real .env files are secret; use .env.example "
              "(AGENTS.md / docs/ai-agents.md). Ask the human to run it if it is really needed.", file=sys.stderr)
        sys.exit(2)

# 2. commands that print the whole environment (tokens are often exported)
dump = re.compile(r"^(env|printenv(\s.*)?|set|export(\s+-p)?|declare\s+-[a-zA-Z]*[px][a-zA-Z]*(\s.*)?|typeset\s+-[a-zA-Z]*x[a-zA-Z]*(\s.*)?|compgen\s+-[ev](\s.*)?)$")
for part in re.split(r"\|\||&&|[;|&\n]", cmd):
    words = part.strip()
    if words.startswith("sudo "):
        words = words[5:].strip()
    if dump.match(words) or "/proc/" in words and "environ" in words:
        print(f"blocked: {words!r} prints environment variables (may include tokens) — "
              "print only the variable you need by name, never its secret value.", file=sys.stderr)
        sys.exit(2)
sys.exit(0)
'

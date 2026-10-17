#!/usr/bin/env bash
# Run once after cloning: prepares local AI-agent config that git cannot carry.
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"

ok()   { printf '  \033[32m✓\033[0m %s\n' "$1"; }
warn() { printf '  \033[33m!\033[0m %s\n' "$1"; }

echo "AI setup for $(basename "$PWD")"

# 1. skills and rules live in .agents/ (shared by every agent; Hermes loads .agents/skills);
#    Claude Code reads them through symlinks .claude/skills and .claude/rules.
#    (Windows checkouts get a plain file instead of a symlink — fall back to a copy)
mkdir -p .claude
for d in skills rules; do
  if [ -L ".claude/$d" ] && [ -d ".claude/$d" ]; then
    ok ".claude/$d symlink"
  else
    rm -rf ".claude/$d"
    if ln -s "../.agents/$d" ".claude/$d" 2>/dev/null && [ -d ".claude/$d" ]; then
      ok ".claude/$d symlink created"
    else
      cp -R ".agents/$d" ".claude/$d"
      warn ".claude/$d copied (symlinks unsupported) — edit .agents/$d and re-run this script"
    fi
  fi
done

# 2. hook must be executable
chmod +x .claude/hooks/*.sh scripts/*.sh
ok "hooks executable"

# 3. personal files (gitignored)
if [ ! -f CLAUDE.local.md ]; then
  cp CLAUDE.local.md.example CLAUDE.local.md
  ok "CLAUDE.local.md created — edit it for your machine"
else
  ok "CLAUDE.local.md exists"
fi
if [ ! -f .env ] && [ -f .env.example ]; then
  cp .env.example .env
  ok ".env created from .env.example — fill in real values"
fi

# 4. tools
for t in git make docker jq gh; do
  if command -v "$t" >/dev/null 2>&1; then ok "$t"; else warn "$t not found"; fi
done
if command -v claude >/dev/null 2>&1; then ok "claude"; else warn "claude (Claude Code) not found — optional"; fi
if command -v hermes >/dev/null 2>&1; then
  if hermes skills trust "$PWD" >/dev/null 2>&1; then ok "hermes: project skills trusted"; else warn "hermes: run 'hermes skills trust' to load .agents/skills"; fi
fi

# 5. placeholders left from the template?
if grep -rIlE '\{\{PROJECT_NAME\}\}' AGENTS.md README.md docs 2>/dev/null | grep -q .; then
  if [ -f scripts/init-project.sh ]; then
    warn "template placeholders still present — run: scripts/init-project.sh <project-name>"
  else
    warn "template placeholders {{...}} still present in AGENTS.md/README.md/docs — fill them in by hand"
  fi
fi

echo "done."

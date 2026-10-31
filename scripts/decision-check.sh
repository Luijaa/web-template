#!/usr/bin/env bash
# Decision and doc triggers of a branch (docs/adr/README.md "ตัวกระตุ้น"): lists what in the diff needs an ADR or a
# doc update, for the PR's "## การตัดสินใจ" section and for the reviewer.
# Fails when application code reads an env var that .env.example does not mention (AGENTS.md: config comes from env
# and must be in .env.example) — checked over the whole tree, not only the diff, so drift on main shows up too.
# usage: scripts/decision-check.sh [--base <ref>] [--body <file>] [--warn]
#   --base  branch to compare with (default origin/main, else main)
#   --body  PR description file: warn when a trigger is found but there is no "## การตัดสินใจ" section
#   --warn  never fail; print GitHub warnings instead
set -euo pipefail

base="" body="" warn=false
while [ $# -gt 0 ]; do
  case "$1" in
    --base) base="$2"; shift 2 ;;
    --body) body="$2"; shift 2 ;;
    --warn) warn=true; shift ;;
    *) echo "usage: $0 [--base <ref>] [--body <file>] [--warn]" >&2; exit 2 ;;
  esac
done
if [ -z "$base" ]; then
  if git rev-parse -q --verify origin/main >/dev/null; then base=origin/main; else base=main; fi
fi
cd "$(git rev-parse --show-toplevel)"
mb=$(git merge-base "$base" HEAD)

# application code only — not tests, e2e, tooling scripts, CI or docs
code=( . ':(exclude,glob)**/*_test.go' ':(exclude,glob)**/*.spec.ts' ':(exclude,glob)**/*.test.ts'
  ':(exclude,glob)**/test_*.py' ':(exclude,glob)**/tests/**' ':(exclude,glob)e2e/**' ':(exclude,glob)scripts/**'
  ':(exclude,glob).github/**' ':(exclude,glob)**/node_modules/**' ':(exclude,glob)docs/**' ':(exclude,glob)**/*.md' )
# Go os.Getenv/LookupEnv (and getEnv helpers), Python os.getenv/os.environ, Node process.env
env_re='(Getenv|LookupEnv|getEnv|getenv)\("[A-Z][A-Z0-9_]*"|process\.env\.[A-Z][A-Z0-9_]*|os\.environ(\.get\(|\[)"[A-Z][A-Z0-9_]*"'
# set by the platform, not by the operator
platform_env='^(TZ|HOME|PATH|PWD|USER|HOSTNAME|TMPDIR|CI|NODE_ENV)$'

env_names() { grep -oE "$env_re" | grep -oE '"[A-Z][A-Z0-9_]*"|env\.[A-Z][A-Z0-9_]*' | sed -E 's/^"//; s/"$//; s/^env\.//' | grep -vE "$platform_env" | sort -u; }
added() { git diff -U0 "$mb" -- "$@" | grep -E '^\+' | grep -vE '^\+\+\+ ' || true; }
changed=$( { git diff --name-only "$mb"; git ls-files --others --exclude-standard; } | sort -u)
touched() { printf '%s\n' "$changed" | grep -qE "$1"; }

errors="" triggers="" notes=""
add_trigger() { triggers="${triggers}  - $1"$'\n'; }

# 1. env vars read by code but not in .env.example (commented "# NAME=" counts as documented)
if [ -f .env.example ]; then
  missing=""
  for name in $(git grep -h -o -E "$env_re" -- "${code[@]}" | env_names || true); do
    grep -qE "(^|[^A-Z0-9_])${name}=" .env.example || missing="$missing $name"
  done
  [ -n "$missing" ] && errors="${errors}  - env ที่โค้ดอ่านแต่ไม่มีใน .env.example:${missing}"$'\n'
else
  notes="${notes}  - ไม่มี .env.example — ข้ามการตรวจ env"$'\n'
fi

# 2. new env vars in this branch -> README/.env.example/deploy-prod; behaviour-changing switch -> ADR
new_env=$(added "${code[@]}" | env_names || true)
[ -n "$new_env" ] && add_trigger "env ใหม่: $(echo $new_env) → README + .env.example + docs/deploy-prod.md; ถ้าเปลี่ยนพฤติกรรมทั้งระบบ (เปิด/ปิดความปลอดภัย, โหมด) = ADR"

# 3. container privileges / networking
priv=$(added 'compose*.yml' '**/compose*.yml' '**/Dockerfile' 'Dockerfile' | grep -oE '^\+[[:space:]]*(sysctls|cap_add|privileged|security_opt|devices|network_mode|pid|ipc|userns_mode|ports):|^\+[[:space:]]*USER[[:space:]]+root' | sed -E 's/^\+[[:space:]]*//; s/:$//' | sort -u || true)
[ -n "$priv" ] && add_trigger "สิทธิ์/เครือข่ายของ container: $(echo $priv) → ADR + docs/deploy-prod.md"

# 4. schema changes -> design data model; secret-looking columns -> ADR on how secrets are stored
migrations=$( { git diff --name-only --diff-filter=A "$mb"; git ls-files --others --exclude-standard; } | grep -E '(^|/)migrations/' | sort -u || true)
if [ -n "$migrations" ]; then
  if touched '^docs/design/'; then state="แก้ docs/design แล้ว"; else state="docs/design ยังไม่ถูกแก้"; fi
  add_trigger "migration ใหม่: $(echo $migrations) → data model ใน docs/design (${state})"
  secret_cols=$(for f in $migrations; do cat "$f" 2>/dev/null; done | grep -ioE '[a-z_]*(password|secret|token|api_key|apikey|credential)[a-z_]*' | sort -u || true)
  [ -n "$secret_cols" ] && add_trigger "migration มีคอลัมน์ที่น่าจะเก็บ secret: $(echo $secret_cols) → ADR วิธีเก็บ (plaintext/เข้ารหัส/อ้าง env)"
fi

# 5. new dependencies -> dependency table in the PR (docs/dependencies.md)
deps=$( { added 'go.mod' '**/go.mod' | grep -v '// indirect' | grep -oE '^\+[[:space:]]+[a-z0-9.-]+\.[a-z]+/[^ ]+ v[0-9][^ ]*' | awk '{print $2}';
          added 'package.json' '**/package.json' | grep -oE '^\+[[:space:]]+"(@[a-z0-9._-]+/)?[a-z0-9._-]+":[[:space:]]*"[~^]?[0-9][^"]*"' | sed -E 's/^\+[[:space:]]+"//; s/":.*//'; } | sort -u || true)
[ -n "$deps" ] && add_trigger "dependency ใหม่/อัปเกรด: $(echo $deps) → ตาราง dependency ใน PR (docs/dependencies.md)"

# 6. calls to external hosts -> new external system: ADR + C4 (placeholders like example.com/localhost are ignored)
hosts=$(added "${code[@]}" | grep -oE "[\"'\`]https?://[a-z0-9.-]+\.[a-z]{2,}" | sed -E "s#^.https?://##" | grep -vE '(^|\.)(example\.(com|org|net)|localhost|invalid|test|local)$' | sort -u || true)
[ -n "$hosts" ] && add_trigger "เรียกระบบภายนอก: $(echo $hosts) → ถ้าเป็นระบบชนิดใหม่ = ADR + รูป C4 ใน docs/architecture.md"

# 7. secret-looking fields (json/yaml tags) -> how secrets are stored
secret_fields=$(added "${code[@]}" | grep -oiE '(json|yaml):"[a-z_]*(token|secret|password|api_?key|credential)[a-z_]*' | sed -E 's/^[a-zA-Z]+:"//' | sort -u || true)
[ -n "$secret_fields" ] && add_trigger "ฟิลด์ที่น่าจะเป็น secret: $(echo $secret_fields) → อ้าง ADR วิธีเก็บ secret ที่มีอยู่ หรือเขียนใหม่"

# 8. data deletion in code -> retention policy, checked against what screens show
deletes=$(added "${code[@]}" | grep -ciE 'DELETE[[:space:]]+FROM' || true)
[ "${deletes:-0}" -gt 0 ] && add_trigger "โค้ดลบข้อมูล (DELETE FROM ${deletes} จุด) → ถ้าลบอัตโนมัติหรือตามอายุ = ADR นโยบาย retention และเทียบกับข้อมูลย้อนหลังที่หน้าจอ/รายงานใช้"

adr_files=$(printf '%s\n' "$changed" | grep -E '^docs/adr/[0-9]{4}-' || true)

echo "decision-check: vs $(git rev-parse --short "$mb") (${base})"
[ -n "$errors" ] && printf 'ต้องแก้:\n%s' "$errors"
if [ -n "$triggers" ]; then
  printf 'ตัวกระตุ้น (ตอบในหัวข้อ "## การตัดสินใจ" ของ PR — ADR-NNNN หรือ "ไม่ต้อง ADR: <เหตุผล>"):\n%s' "$triggers"
  echo "ADR ใน branch นี้: $(echo ${adr_files:-ไม่มี})"
else
  echo "ไม่พบตัวกระตุ้น"
fi
[ -n "$notes" ] && printf '%s' "$notes"

problems=""
[ -n "$errors" ] && problems="env ที่โค้ดอ่านต้องอยู่ใน .env.example"
if [ -n "$triggers" ] && [ -n "$body" ] && ! grep -qE '^##[[:space:]]+การตัดสินใจ' "$body"; then
  echo "::warning::PR มีตัวกระตุ้นแต่ไม่มีหัวข้อ \"## การตัดสินใจ\" (docs/adr/README.md)"
fi
if [ -n "$problems" ]; then
  if $warn; then echo "::warning::${problems}"; exit 0; fi
  echo "$problems" >&2
  exit 1
fi

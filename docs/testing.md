# Testing

| ชั้น | คำสั่ง | รันใน CI (job) | ครอบอะไร |
|---|---|---|---|
| lint + type + **SAST** | `make lint` | `check` | style, type error, รูปแบบโค้ดที่เสี่ยงช่องโหว่ (injection, crypto อ่อน, path traversal) |
| unit/integration | `make test` | `check` | logic, validation, API handler, ไฟล์แปลมี key ครบทุกภาษา, การหา IP ผู้ใช้หลัง proxy |
| build | `make build` | `check` | Dockerfile build ได้ |
| **e2e** | `make e2e` | `e2e` | ผู้ใช้ทำงานหลักได้จริงบน **production image** (login, flow หลัก, สิทธิ์) |
| license | `make license` | `check` | license ของ dependency ใน image ตาม `docs/dependencies.md` |
| **DAST** | `make dast` | `dast` | สแกน production image ที่รันอยู่ด้วย ZAP baseline: security header, cookie flag, error รั่ว |
| security | trivy (ใน CI) | `security` | dependency มีช่องโหว่ HIGH/CRITICAL ที่แก้ได้, secret ที่ commit, misconfig ของ Dockerfile/compose |
| image | — | `image` | build ได้ทั้ง amd64 + arm64 และ **สแกน CVE ของ image ก่อน push** (trivy image: package ของ OS ใน base image + runtime/library ที่ compile อยู่ในแอป — CRITICAL/HIGH ที่แก้ได้ = แดง) |
| image-rescan | — | `image-rescan` (ทุกวันจันทร์ + กดเองได้) | สแกน `:main` (dev) และ `:latest` (production) ซ้ำ หา CVE ที่ประกาศหลัง build — เจอ = เปิด/อัปเดต issue `[security] CVE ใน image :<tag>` label `security`, สแกนผ่านรอบถัดไปปิด issue เอง |

PR merge ได้เมื่อทุก job เขียว (check, e2e, dast, security, image)

## CI runners

โปรเจกต์นี้รัน CI บน: **{{CI_RUNNERS}}**

เลือกครั้งเดียวตอนสร้างโปรเจกต์ (`scripts/init-project.sh --runner github|self-hosted`) — เปลี่ยนทีหลังให้แก้ `runs-on` ใน `.github/workflows/*.yml` ตามตารางนี้ใน PR แยก:

| job | GitHub-hosted | self-hosted |
|---|---|---|
| ci: `check`, `e2e` · image: build `linux/amd64` | `ubuntu-24.04` | `[self-hosted, Linux, X64]` |
| image: build `linux/arm64` | `ubuntu-24.04-arm` | `[self-hosted, Linux, ARM64]` |
| ci: `dast`, `security` · image: `guard`, `publish`, `cleanup`, `release` · `image-rescan` | `ubuntu-24.04` | `[self-hosted, Linux, ARM64]` (แบ่งงานให้ 2 เครื่องไม่ต่อคิวกัน) |

- self-hosted: เลือกด้วย label มาตรฐานเท่านั้น ไม่อ้างชื่อเครื่อง; ต้องมี runner ทั้ง X64 และ ARM64 (build image แต่ละ arch บนเครื่อง arch นั้น ไม่ใช้ QEMU) และมี `docker` + buildx + compose, `git`, `make`, `python3`, `jq`, `openssl`, `gh`
- **self-hosted ใช้กับ repo private เท่านั้น** — repo public ให้ PR จาก fork รันโค้ดบนเครื่องเราได้ (`init-project.sh` ปฏิเสธถ้าเห็นว่า repo เป็น public)
- **ห้าม bind mount ไฟล์ใน repo เข้า container** ทั้งใน workflow, `scripts/` และ `compose.e2e.yml` (`-v "$PWD:/src"`, `-v $(CURDIR):…`, `./x:/y`): runner ที่เป็น container สั่ง Docker ของ host ซึ่งไม่มี path ของ checkout → container เห็น**โฟลเดอร์ว่างโดยไม่ error** (trivy สแกนว่างแล้วผ่าน) — ใช้ `docker create` → `docker cp` เข้า → `docker start -a` (ได้ exit code ของ container) → `docker cp` ผลออก; trivy ใช้ `scripts/trivy.sh` (copy repo เข้า `/src` ให้), mount `/var/run/docker.sock` ได้เพราะเป็น path ของ host
- ไฟล์ชั่วคราวของ job ใช้ `$RUNNER_TEMP` ไม่ใช้ `/tmp/...` ตรง ๆ (self-hosted ไม่ล้าง `/tmp` ระหว่าง job)

## e2e (Playwright)

รันกับ image ตัวเดียวกับที่ขึ้น production (Dockerfile target runner) ไม่ใช่ dev server — จับปัญหาแบบที่ unit test มองไม่เห็น เช่น หน้า login ไม่ hydrate, healthcheck, env หาย

โครงที่ใช้ (ตัวอย่างจริง: oncall-app):

- `e2e/` — `package.json` (`@playwright/test` pin เวอร์ชันตรงกับ image), `playwright.config.ts`, `tests/*.spec.ts`
- `compose.e2e.yml` — service `web` (build target runner + env ทดสอบ) และ `e2e` (`mcr.microsoft.com/playwright:vX.Y.Z-noble`, profile `test`)
- `scripts/e2e.sh` — สุ่ม secret/รหัสผ่านทดสอบ → `up --wait` → seed → รัน Playwright → `down -v --rmi local` เสมอ
  - ใช้ compose project ไม่ซ้ำต่อรัน: `docker compose -p "$(basename "$PWD" | tr '[:upper:]' '[:lower:]' | tr -c 'a-z0-9\n' '-')-e2e-$$" -f compose.e2e.yml` — หลาย agent (coder, coder2, reviewer) รัน e2e พร้อมกันใน worktree แยกบนเครื่องเดียว ถ้าใช้ `name:` ใน compose.e2e.yml อย่างเดียว ตัวหนึ่งจะสร้าง container ทับและ `down -v` ลบของอีกตัว
  - ห้าม publish port ใน compose.e2e.yml (Playwright เรียก `web` ผ่าน network ของ compose) — port ที่ publish จะชนกันเมื่อรันพร้อมกัน
- report เมื่อ fail: `e2e/.results/report/index.html` (CI แนบเป็น artifact `e2e-report`)

กติกา:

- ฟีเจอร์ที่ผู้ใช้เห็น ต้องมี e2e อย่างน้อย 1 เส้นของ flow หลักใน PR เดียวกัน
- เลือก element ด้วย role/ข้อความที่ผู้ใช้เห็น หรือ `id` ของ form — ไม่ใช้ class CSS
- test ต้องไม่พึ่งข้อมูลจาก test อื่น (สร้างข้อมูลเองด้วยชื่อไม่ซ้ำ)
- หลายภาษา/theme/accessibility ตาม `docs/ui.md`: สลับภาษาแล้วข้อความ flow หลักเปลี่ยนและคงอยู่หลัง reload; สลับ theme แล้ว `<html data-theme>` เปลี่ยนและคงอยู่; `test.use({ colorScheme: 'dark' })` + โหมด system แสดงสีมืด; `@axe-core/playwright` (tags `wcag2a` `wcag2aa` `wcag21aa` `wcag22aa`) ไม่มี violation ในหน้าหลักทั้ง light และ dark
- เลือก element ด้วยข้อความที่ผู้ใช้เห็น → ใช้ข้อความจากไฟล์แปลของภาษาที่ test ตั้งไว้ (ตั้ง `locale: 'th-TH'` ใน config ให้แน่นอน)
- อัปเกรด Playwright: แก้ `e2e/package.json` และ tag image ใน `compose.e2e.yml` พร้อมกัน
- รัน e2e แบบไม่ bind mount (ดู "CI runners"): `up --no-start --no-deps e2e` → `docker cp e2e <container>:/src` → `docker start -a <container>` → `docker cp <container>:/tmp/out/. e2e/.results/` (service `e2e` ไม่มี `volumes:`, ตั้ง `E2E_OUT: /tmp/out` และ command `cp -r /src /tmp/e2e && rm -rf /tmp/e2e/node_modules /tmp/e2e/.results && cd /tmp/e2e && npm ci && npx playwright test`) — ห้ามลืม `--no-deps`: compose บาง version จะ recreate `web` ที่ seed แล้ว (DB ว่าง → login ไม่ผ่านเฉพาะบน CI)
- test ที่สลับ theme แล้วตรวจ axe ต้องรอ CSS transition จบก่อน (`document.getAnimations().filter(a => a instanceof CSSTransition)` → `finished`) — runner เร็วจะตรวจเจอสีระหว่าง transition
- `compose.e2e.yml` ตั้ง `TZ: Asia/Bangkok` เหมือน production และมี test อย่างน้อย 1 ข้อที่ตรวจว่าเวลาที่แสดงเป็นเวลาไทย (ข้อมูลข้ามเที่ยงคืน UTC เช่น 17:30Z → 00:30 วันถัดไป)
- report อยู่ใน `e2e/.results/` (ขึ้นต้นด้วยจุด) — `actions/upload-artifact` ต้องใส่ `include-hidden-files: true`

## SAST (อยู่ใน `make lint`)

ตั้งตอนเลือก stack — ใช้ rule ด้านความปลอดภัยของ linter ที่ใช้อยู่แล้ว ไม่ต้องลงเครื่องมือแยก:

| stack | ตั้งค่า |
|---|---|
| Go | `golangci-lint` เปิด `gosec`: `.golangci.yml` → `version: "2"` + `linters: { enable: [gosec] }` |
| Node / TypeScript | `eslint-plugin-security` (`configs.recommended` ใน `eslint.config.js`) + `eslint-plugin-no-unsanitized` ถ้าแตะ DOM |
| Python | `ruff` เปิดกลุ่ม `S` (flake8-bandit): `[tool.ruff.lint] extend-select = ["S"]` |

- ปิด rule เฉพาะบรรทัดได้เมื่อมีเหตุผลต่อท้ายเสมอ: `//nolint:gosec // G304: path มาจาก config ไม่ใช่ผู้ใช้`, `# noqa: S603 — <เหตุผล>`, `// eslint-disable-next-line security/<rule> -- <เหตุผล>` — ไม่มีเหตุผล หรือปิดทั้งไฟล์/ทั้ง repo = reviewer ให้แก้
- ไม่ใช้ CodeQL: ใช้กับ private repo ของ org ได้เฉพาะเมื่อซื้อ GitHub Advanced Security
- SAST จับได้แค่รูปแบบโค้ด ไม่รู้กฎธุรกิจ — เรื่องสิทธิ์และ id ของผู้ใช้อื่น (`.agents/rules/api.md`) ยังต้องมี test และ reviewer

## DAST: ZAP baseline (`make dast`)

สแกนแบบ passive (spider + ตรวจ response ไม่ยิง payload โจมตี) กับ production image ที่รันใน compose ชั่วคราว — จับสิ่งที่ unit test มองไม่เห็น เช่น ลืม security header, cookie ไม่มี `HttpOnly`/`SameSite`, หน้า error แสดง stack trace

- กฎอยู่ใน `.zap/rules.tsv`: `FAIL` ทำให้ CI แดง, `WARN` แสดงใน report, `IGNORE` ข้าม — rule ที่ไม่ได้ระบุเป็น `WARN`; ลด `FAIL` เป็น `WARN`/`IGNORE` ต้องบอกเหตุผลใน PR
- image `ghcr.io/zaproxy/zaproxy:2.17.0` (Apache-2.0, multi-arch, ~3.6 GB — ใช้ใน CI/dev เท่านั้น ไม่อยู่ใน image ของแอป); ใช้เวลา ~2 นาที
- baseline สแกนเฉพาะหน้าที่ไม่ต้อง login (หน้า login, healthz, static) — header ที่ตั้งเป็น middleware กลางจะถูกตรวจครบอยู่แล้ว

ตั้งตอนเลือก stack (ใช้ `compose.e2e.yml` ตัวเดียวกับ e2e):

```yaml
# compose.e2e.yml — เพิ่ม service
  zap:
    image: ghcr.io/zaproxy/zaproxy:2.17.0
    profiles: [dast]
    depends_on:
      web:
        condition: service_healthy
    # no bind mount — scripts/dast.sh copies .zap/.results in as /zap/wrk and the report back out
    command: zap-baseline.py -t http://web:8080 -c rules.tsv -I -r report.html -J report.json
```

```bash
# scripts/dast.sh — Makefile: dast: ; scripts/dast.sh
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"
P="$(basename "$PWD" | tr '[:upper:]' '[:lower:]' | tr -c 'a-z0-9\n' '-')-dast-$$"
compose=(docker compose -p "$P" -f compose.e2e.yml)
trap '"${compose[@]}" --profile dast down -v --remove-orphans --rmi local >/dev/null 2>&1 || true' EXIT
rm -rf .zap/.results && mkdir -p .zap/.results && cp .zap/rules.tsv .zap/.results/
chmod 777 .zap/.results            # ZAP runs as uid 1000
# set the env web needs to start (random secrets, as in scripts/e2e.sh)
"${compose[@]}" up -d --build --wait web
# rules in, report out with docker cp — no bind mount ("CI runners")
"${compose[@]}" --profile dast up --no-start --no-deps zap < /dev/null
cid="$("${compose[@]}" --profile dast ps -a -q zap)"
docker cp .zap/.results "$cid:/zap/wrk"
rc=0; docker start -a "$cid" < /dev/null || rc=$?   # exit 1 = a FAIL rule hit
docker cp "$cid:/zap/wrk/." .zap/.results/ > /dev/null 2>&1 || true
exit "$rc"
```

- `-I` = ไม่ fail เพราะ WARN; exit 1 = มี FAIL; exit 3 = ZAP เองมีปัญหา (เช่น ต่อ `web` ไม่ได้)
- report: `.zap/.results/report.html` (CI แนบเป็น artifact `zap-report` เมื่อ fail)

## Security findings

- แก้ด้วยการอัปเกรด dependency (Dependabot เปิด PR ให้ทุกวันจันทร์)
- CVE ใน image (job `image` หรือ issue จาก `image-rescan`): อัปเดต base image (`FROM` tag/patch ใหม่ — Dependabot ecosystem `docker`) หรือ dependency/Go version ให้ถึงเวอร์ชันที่แก้ → merge → deploy dev; production ต้องออก release ใหม่
- ถ้ายังแก้ไม่ได้: เพิ่มใน `.trivyignore` พร้อมเหตุผล + `exp:YYYY-MM-DD` (หมดอายุแล้ว CI จะแดงอีกครั้ง)

# สูตร: Go + Chi + SQLite + Vue 3 SPA (Bun, Vite, Tailwind 4)

> ต้นแบบ: pulse-app `6ec2cf0` (ผ่าน CI check/e2e/dast/security/image) — เวอร์ชัน ณ 28 ต.ค. 2026 ตรวจใหม่ก่อนใช้
> ✚ = ยังไม่มีในต้นแบบ หรือต้นแบบทำผิดแล้วต้องแก้ตามกฎปัจจุบันของ template

ใช้เมื่อหน้าจอโต้ตอบเยอะ (dashboard, ฟอร์มหลายขั้น, กราฟ) แต่ยังอยากได้ binary เดียวแบบ `go-templ-htmx.md` — Vue build เป็นไฟล์ static แล้ว embed เข้า Go binary ไม่มี Node ใน image

## โครงสร้าง

```
cmd/server/main.go           entrypoint: serve (ค่าเริ่มต้น) | healthcheck | seed (✚ ถ้ามีผู้ใช้)
internal/server/             router, middleware (security header, trusted proxy), health, เสิร์ฟ SPA
internal/<โดเมน>/             handler + service + repository ต่อโดเมน ชื่อตาม CONTEXT.md
internal/db/db.go            เปิด SQLite + รัน goose
internal/db/migrations/NNNNN_<ชื่อ>.sql   (//go:embed migrations/*.sql ใน db.go)
web/embed.go                 //go:embed all:dist → fs.Sub("dist")
web/src/                     Vue: main.ts, App.vue, stores/ (Pinia), i18n/, locales/{th,en}.json, style.css
web/scripts/check-i18n.js    เทียบชุด key ของทุกไฟล์แปล (อยู่ใน `bun run lint`)
e2e/                         Playwright (npm — image ของ Playwright มี Node)
scripts/e2e.sh, scripts/dast.sh
Dockerfile, compose.yml, compose.dev.yml, compose.prod.yml, compose.e2e.yml
```

แอปเป็น container เดียว (`CONTEXT=.`, `TARGET=runner` ใน `image.yml`) — โฟลเดอร์ `web/` ของ template ใช้เป็นที่อยู่ของ Vue, ลบ `api/` ทิ้ง; ปรับตาราง container ใน `docs/architecture.md`

## เวอร์ชันที่ใช้

| ส่วน | เวอร์ชัน | license | หมายเหตุ |
|---|---|---|---|
| Go | 1.26 (N-1) | BSD-3 | `go 1.26.x` ใน go.mod, image `golang:1.26.x-alpine`; CI `setup-go` `1.26.x` + `check-latest: true` |
| alpine (runner) | 3.23.x | MIT | `apk add tzdata ca-certificates` |
| chi | v5.4 | MIT | router |
| goose | v3.29 | MIT | migration embed ใน binary |
| modernc.org/sqlite | v1.60 | BSD-3 | pure Go — `CGO_ENABLED=0`, multi-arch ง่าย |
| golangci-lint | v2.14.0 | GPL-3.0 (เครื่องมือ dev ไม่อยู่ใน image) | |
| Bun | 1.4.x | MIT | ติดตั้ง/build ฝั่ง web เท่านั้น (image `oven/bun:<ver>-alpine` ใน stage build) — ไม่อยู่ใน image สุดท้าย |
| Vue | 3.5 | MIT | |
| Pinia | 4.0 | MIT | major ใหม่กว่าที่โมเดลมักจำได้ — อ่าน migration guide |
| Vite | 8.3 | MIT | + `@vitejs/plugin-vue` 6 |
| TypeScript | 6.0 | Apache-2.0 | + `vue-tsc` 3 |
| Tailwind CSS | 4.3 | MIT | `@tailwindcss/vite` — ไม่มี `tailwind.config.js` |
| eslint | 10 | MIT | `eslint-plugin-vue` 10 + `typescript-eslint` 8 |
| Playwright | 1.63 | Apache-2.0 | `e2e/package.json` ตรงกับ image `mcr.microsoft.com/playwright:v<ver>-noble` |

Vite 8, TypeScript 6, Pinia 4, Tailwind 4 ล้วนข้าม major จากที่โมเดลคุ้น — skill ของ stack (ด้านล่าง) + lint deprecated มีไว้กันเรื่องนี้โดยตรง

## skill ของ stack

คัดลอกเข้า `.agents/skills/` ใน PR ตั้ง stack แล้วตรวจเวอร์ชันในแต่ละไฟล์ให้ตรง `go.mod`/`web/package.json`:

| skill | ที่มา | ใช้เมื่อ |
|---|---|---|
| `chi-spa-patterns` | `skills/go-vue-spa/` | route, middleware, เสิร์ฟ SPA ที่ embed, health, error แบบ RFC 9457 |
| `vue-pinia-patterns` | `skills/go-vue-spa/` | component, store, เรียก API, i18n, polling |
| `tailwind4-patterns` | `skills/go-vue-spa/` | token, dark mode 3 โหมด, class ใน component |
| `sqlite-go-modernc` | `skills/go-templ-htmx/` (ใช้ร่วม) | DSN/PRAGMA, pool, migration ด้วย goose |
| `go-testing-patterns` | `skills/go-templ-htmx/` (ใช้ร่วม) | table-driven test, `httptest` กับ chi, เวลา/timezone |

ไลบรารีเฉพาะโปรเจกต์ (เช่น Chart.js) เขียน skill เพิ่มใน PR แยกตามชุดที่อนุมัติใน ADR-0001

## Makefile

```make
COMPOSE ?= docker compose
GOLANGCI := bin/golangci-lint-v2.14.0

setup: ## install dependencies
	go mod download
	bun --cwd=web install --frozen-lockfile
	bun --cwd=web run build

$(GOLANGCI):
	GOBIN=$(CURDIR)/bin go install github.com/golangci/golangci-lint/v2/cmd/golangci-lint@v2.14.0
	mv bin/golangci-lint $@

web/dist/index.html:
	bun --cwd=web run build

lint: $(GOLANGCI) web/dist/index.html ## lint + format check + SAST
	bun --cwd=web run lint
	$(GOLANGCI) run

test: web/dist/index.html ## unit/integration tests
	go test -race ./...

build: ## build container images
	$(COMPOSE) build

e2e: ## end-to-end tests on the production image
	SPEC="$(SPEC)" ./scripts/e2e.sh

dast: ## ZAP baseline scan of the running production image
	./scripts/dast.sh

license: ## open-source license check
	go mod download
	GO_MODULES=1 scripts/trivy.sh fs --quiet --config /src/.trivy-license.yaml --ignorefile /src/.trivyignore-license.yaml \
	  --scanners license --severity CRITICAL,HIGH,UNKNOWN --exit-code 1 /src
```

- `//go:embed all:dist` ต้องมี `web/dist` ก่อน `go build`/`go test`/`golangci-lint` — ไม่มีจะ error `pattern all:dist: no matching files found`; target `web/dist/index.html` สร้างให้ครั้งแรก (แก้ Vue แล้ว `bun --cwd=web run build` ใหม่ก่อน test ที่อ่าน dist)
- ✚ ต้นแบบติดตั้ง golangci-lint ด้วย `which golangci-lint || go install` — เครื่องที่มีเวอร์ชันอื่นจะไม่ถูกเปลี่ยน ใช้ binary ใน `bin/` ที่มีเวอร์ชันในชื่อแบบด้านบน (เพิ่ม `bin/` ใน `.gitignore`)
- ✚ ต้นแบบ `setup` รัน `go mod tidy` — ห้าม: CI ต้องไม่แก้ go.mod เอง ใช้ `go mod download` แล้วให้ test พังถ้า go.mod ไม่ tidy
- `web/package.json`:
  ```json
  "scripts": {
    "dev": "vite",
    "build": "vue-tsc -b && vite build",
    "lint": "vue-tsc --noEmit && eslint src && node scripts/check-i18n.js"
  }
  ```
- CI job `check`: เพิ่ม `oven-sh/setup-bun@v2` (`bun-version` ตรงกับ Dockerfile) ถัดจาก `actions/setup-go`

## lint (SAST + API deprecated)

`.golangci.yml`:
```yaml
version: "2"
linters:
  default: standard
  enable: [staticcheck, gosec, bodyclose, errorlint, noctx, sqlclosecheck]
  settings:
    staticcheck:
      checks: ["all", "-ST1000", "-ST1003", "-ST1016", "-ST1020", "-ST1021", "-ST1022"]   # SA1019 = API deprecated
  exclusions:
    presets: [std-error-handling, common-false-positives]
    rules:
      - path: '.*_test\.go'
        linters: [gosec, errcheck, noctx]
formatters:
  enable: [gofmt, goimports]
```

`web/eslint.config.js`: `pluginVue.configs['flat/essential']` (มีกฎ `vue/no-deprecated-*`) + `typescript-eslint` แบบ type-aware (`parserOptions.project`) ทั้ง `.ts` และ `.vue` พร้อม `'@typescript-eslint/no-deprecated': 'error'`; ✚ เพิ่ม `eslint-plugin-security` ตาม `docs/testing.md`

## Dockerfile

```dockerfile
FROM oven/bun:1.4.3-alpine AS frontend-builder
WORKDIR /src/web
COPY web/package.json web/bun.lock ./
RUN bun install --frozen-lockfile
COPY web/ ./
RUN bun run build

FROM golang:1.26.10-alpine AS builder
WORKDIR /src
COPY go.mod go.sum ./
RUN go mod download
COPY . .
COPY --from=frontend-builder /src/web/dist ./web/dist
RUN CGO_ENABLED=0 go build -trimpath -ldflags="-w -s" -o /app/server ./cmd/server

FROM alpine:3.23.6 AS runner
RUN apk add --no-cache tzdata ca-certificates \
 && addgroup -g 1000 appuser && adduser -u 1000 -G appuser -D appuser \
 && mkdir -p /app/data && chown -R appuser:appuser /app
WORKDIR /app
COPY --from=builder --chown=appuser:appuser /app/server /app/server
USER appuser
EXPOSE 8080
HEALTHCHECK --interval=30s --timeout=5s --retries=3 CMD ["/app/server", "healthcheck"]
ENTRYPOINT ["/app/server"]
```

- `import _ "time/tzdata"` ใน main.go ด้วย
- `.dockerignore`: `.git`, `bin/`, `e2e/`, `.zap/`, `web/node_modules`, `web/dist`, `*.db`
- ทั้ง 3 stage เป็น multi-arch (bun, golang, alpine มี arm64)

## SQLite + migration (✚ ตั้งแต่ตารางแรก)

- **schema ทุกตารางมาจาก goose ตั้งแต่ PR ตั้ง stack** — ต้นแบบ PR แรกสร้างตารางด้วย `CREATE TABLE IF NOT EXISTS` ในโค้ดตอนเริ่มแอป พอ PR ถัดไปเปลี่ยนมาใช้ goose, DB dev ที่มีตารางเก่าทำให้ migration ข้ามตารางเงียบ ๆ แล้วล้มที่ `CREATE INDEX` — container restart วนจนต้องล้าง DB
- ส่วน Up ห้าม `IF NOT EXISTS` (`.agents/rules/api.md`)
- `internal/db/db.go`: DSN `file:<path>?_pragma=busy_timeout(5000)&_pragma=journal_mode(WAL)&_pragma=foreign_keys(ON)` + `SetMaxOpenConns(1)` → ping (timeout 2 วินาที) → `goose.SetBaseFS(migrationsFS)` + `goose.SetDialect("sqlite3")` + `goose.Up(db, "migrations")` ก่อนเปิดรับ request
- migration ล้ม = แอปออกด้วย error (container restart วน) — ops rollback image ตาม deploy-dev; ห้ามทำให้แอปขึ้นได้ทั้งที่ schema ผิด
- test ใช้ `:memory:` + `goose.Up` ชุดเดียวกับของจริง (ห้ามสร้างตารางใน test แยก)

## Health, shutdown, security header

- `/healthz` (liveness) ตอบ 200 เสมอ; `/readyz` ping DB (timeout 2 วินาที) + 503 เมื่อกำลังปิด; subcommand `healthcheck` เรียก `http://127.0.0.1:$PORT/readyz`
- `middleware.RequestID` → `Recoverer` → `GetHead` → trusted proxy (แทน `RemoteAddr` เฉพาะเมื่อมาจาก `TRUSTED_PROXIES`) → security header
- CSP ของต้นแบบ: `default-src 'self'; script-src 'self'; style-src 'self' 'unsafe-inline'; img-src 'self' data:; connect-src 'self'; font-src 'self'; frame-ancestors 'none'; base-uri 'self'; form-action 'self'` — ✚ ลองตัด `'unsafe-inline'` ออกจาก `style-src` แล้วรัน `make e2e` + `make dast` (`:style` ของ Vue ตั้งค่าผ่าน CSSOM ซึ่ง CSP ไม่บล็อก)
- shutdown: SIGTERM → ตั้งสถานะกำลังปิด (`/readyz` 503) → หยุดงานเบื้องหลัง → `server.Shutdown` timeout 10 วินาที; compose `stop_grace_period: 15s`
- `http.Server` ตั้ง `ReadHeaderTimeout`/`ReadTimeout`/`WriteTimeout`/`IdleTimeout` (gosec G112)

## เสิร์ฟ SPA

- `web/embed.go` (`package web`): `//go:embed all:dist` + `func Dist() (fs.FS, error) { return fs.Sub(distFS, "dist") }`
- route `/*`: มีไฟล์ใน dist → `http.FileServer`; ไม่มี → ส่ง `index.html` (client-side routing)
- ✚ path ใต้ `/api/` ที่ไม่มี route ต้องได้ 404 แบบ `application/problem+json` ไม่ใช่ `index.html` — ต้นแบบส่ง `index.html` 200 ให้ `/api/<อะไรก็ได้>` ที่อยู่นอก subrouter
- ✚ cache: `/assets/*` (ชื่อไฟล์มี hash) `Cache-Control: public, max-age=31536000, immutable`; `index.html` `no-cache`
- dev: `bun --cwd=web run dev` + `vite.config.ts` `server.proxy` ส่ง `/api`, `/healthz`, `/readyz` ไป `http://localhost:8080`

## i18n และ theme

- i18n: `web/src/i18n/index.ts` — `ref<Locale>` + `t(key, params)` อ่าน `locales/{th,en}.json` (import JSON); เลือกภาษาจาก cookie `locale` → `navigator.language` → ค่าเริ่มต้นตาม `docs/ui.md` (`th`) หรือตาม design ของโปรเจกต์; ตั้ง `document.documentElement.lang` ทุกครั้งที่เปลี่ยน; `check-i18n.js` ทำให้ lint พังเมื่อ key ไม่ครบทุกภาษา
- theme 3 โหมด (`system`/`light`/`dark`) ด้วย `data-theme` บน `<html>` + `@custom-variant dark` ของ Tailwind 4 (skill `tailwind4-patterns`); `<meta name="color-scheme" content="light dark">` ใน `index.html`
- ✚ กันจอกระพริบตอนโหลด: CSP ห้าม inline script จึงใช้ `web/public/theme-init.js` (อ่าน cookie/`localStorage` แล้วตั้ง `data-theme`) โหลดแบบ `<script src="/theme-init.js"></script>` ใน `<head>` ก่อน CSS
- ✚ `localStorage` ครอบ `try/catch` ทุกครั้ง (private mode / ถูกบล็อกจะ throw)

## compose

- `compose.yml`: service `app` (`build: .`), `env_file: .env`, `TZ: Asia/Bangkok`, `DB_PATH: /app/data/<ชื่อ>.db`, volume `app-data:/app/data`, port `127.0.0.1:${APP_PORT:-8080}:8080`, limit + healthcheck `["CMD", "/app/server", "healthcheck"]`; ✚ `stop_grace_period: 15s`
- `compose.dev.yml`: `image: ghcr.io/<owner>/<repo>:${IMAGE_TAG:-main}` (ops rollback ใช้ `IMAGE_TAG`), `container_name: <repo>-dev`, network ของ reverse proxy แบบ external, `TRUSTED_PROXIES: <subnet ของ network proxy>`
- `compose.prod.yml` ตรงกับ `compose.yml` (image จาก GHCR, ไม่ build)

## e2e และ DAST

- `compose.e2e.yml`: `web` (`build: {context: ., target: runner}`, healthcheck interval 5s), `e2e` (image Playwright, profile `test`, `npm ci` ใน container), `zap` (profile `dast`)
- `scripts/e2e.sh` ของต้นแบบ: project `-p <repo>-e2e-$$`, `up --wait web`, คัดลอก `e2e/` เข้า container ด้วย `docker cp` (ไม่ bind mount — `docs/testing.md` "CI runners"), `down -v --rmi local` เสมอ
- e2e ขั้นต่ำของ PR ตั้ง stack: หน้าแรกโหลดได้ทั้ง `th`/`en`, สลับ theme แล้วค้างหลัง reload, `/healthz` `/readyz` 200, `HEAD /` ไม่ใช่ 405

## กับดักที่เจอในต้นแบบ

- **ไม่มีสูตรตอนเริ่ม** → PR ตั้ง stack ใหญ่ ~2,900 บรรทัดและวางโครงเอง (schema ในโค้ด, endpoint ตัวอย่างข้อมูลปลอม) — สูตรนี้มีไว้กันเรื่องนี้; PR ตั้ง stack ตามสูตรควรมีแค่โครง + หน้าแรก + health ไม่มีฟีเจอร์
- ลบ handler ตัวอย่าง/ข้อมูลจำลอง (`[{"id": "1", ...}]`, URL ภายในองค์กร) ก่อน merge — ต้นแบบหลงเหลือ handler ปลอมคู่กับของจริงหลาย PR
- `go mod tidy` ย้าย dependency จาก `// indirect` เป็น direct เมื่อโค้ดเริ่ม import ตรง (เช่น `google/uuid`) — commit go.mod ด้วยเสมอ
- config แบบ Tailwind 3 (`tailwind.config.js`, `darkMode: 'class'`, `@tailwind base`) ใช้กับ v4 ไม่ได้ — ดู skill `tailwind4-patterns`

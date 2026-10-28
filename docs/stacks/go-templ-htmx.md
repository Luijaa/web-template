# สูตร: Go + Chi + Templ + HTMX + SQLite

> ต้นแบบ: itms-app `879eda6` (ผ่าน CI check/e2e/security/image, image บีบอัด ~10 MB / คลาย ~35 MB, RAM ~11 MiB ขณะใช้งาน dev) — เวอร์ชัน ณ 14 ต.ค. 2026 ตรวจใหม่ก่อนใช้
> ✚ = ยังไม่มีในต้นแบบ ต้องเพิ่มตามกฎปัจจุบันของ template

## โครงสร้าง

```
cmd/server/main.go        entrypoint: serve (ค่าเริ่มต้น) | seed | healthcheck
internal/<โดเมน>/          handler + service (กฎสิทธิ์) + store ต่อโดเมน ชื่อตาม CONTEXT.md
internal/db/db.go         เปิด SQLite + รัน goose
internal/templates/*.templ หน้าจอ (go generate ด้วย templ)
migrations/NNNNN_<ชื่อ>.sql + migrations.go (//go:embed *.sql)
locales/th.json, locales/en.json   ✚ ไฟล์แปล (go-i18n)
e2e/                      Playwright
scripts/e2e.sh, scripts/dast.sh, scripts/backup.sh
Dockerfile, compose.yml, compose.dev.yml, compose.prod.yml, compose.e2e.yml
```

แอปเป็น container เดียว (`CONTEXT=.` และ `TARGET=runner` ใน `image.yml`) — ไม่ใช้โฟลเดอร์ `web/` `api/` ของ template; ปรับตาราง container ใน `docs/architecture.md` ตาม

## เวอร์ชันที่ใช้

| ส่วน | เวอร์ชัน | license | หมายเหตุ |
|---|---|---|---|
| Go | 1.26 (N-1; N = 1.27) | BSD-3 | `go 1.26.0` ใน go.mod, image `golang:1.26-alpine` |
| alpine (runner) | 3.23.x | MIT | `apk add tzdata ca-certificates` |
| chi | v5 | MIT | router |
| templ | v0.3.1020 | MIT | ผ่าน `go tool` (ล็อกใน go.mod) |
| goose | v3.28.0 | MIT | embed migration ใน binary |
| modernc.org/sqlite | v1.60 | BSD-3 | pure Go — ไม่ต้อง CGO, build multi-arch ง่าย |
| golangci-lint | v2.14.0 | GPL-3.0 (เครื่องมือ dev ไม่อยู่ใน image — ใช้ได้) | ✚ ต้นแบบยังใช้ v1.64 |
| go-i18n | v2.6 | MIT | ✚ i18n + CLDR plural |

## skill ของ stack

คัดลอก `docs/stacks/skills/go-templ-htmx/*` ไปที่ `.agents/skills/` ใน PR scaffold แล้วตรวจเวอร์ชันในแต่ละไฟล์ให้ตรง `go.mod` (เช่น htmx ใน `htmx-web-patterns`):

| skill | ใช้เมื่อ |
|---|---|
| `templ-go-patterns` | เขียน/แก้ `.templ` และ render ใน handler |
| `htmx-web-patterns` | partial update, polling, modal, `hx-boost`, response header ของ htmx |
| `sqlite-go-modernc` | DSN/PRAGMA, connection pool, migration ด้วย goose |
| `go-testing-patterns` | table-driven test, `httptest` กับ chi, test helper, เวลา/timezone |

เพิ่มตัวที่โปรเจกต์ต้องการ (เช่น `pre-pr-check-go` ตาม ADR ของโปรเจกต์) ใน PR แยก พร้อม `source:`

## Makefile

```make
COMPOSE ?= docker compose
GOLANGCI := bin/golangci-lint-v2.14.0

setup: ## install dependencies
	go mod download
	go get -tool github.com/a-h/templ/cmd/templ@v0.3.1020 github.com/pressly/goose/v3/cmd/goose@v3.28.0

$(GOLANGCI):
	GOBIN=$(CURDIR)/bin go install github.com/golangci/golangci-lint/v2/cmd/golangci-lint@v2.14.0
	mv bin/golangci-lint $@

lint: $(GOLANGCI) ## lint + format check + SAST
	go tool templ generate && git diff --exit-code
	$(GOLANGCI) run

test: ## unit/integration tests
	go tool templ generate && go test -race ./...

build: ## build container images
	$(COMPOSE) build

e2e: ## end-to-end tests on the production image
	./scripts/e2e.sh

dast: ## ZAP baseline scan of the running production image
	./scripts/dast.sh

license: ## open-source license check
	go mod download
	GO_MODULES=1 scripts/trivy.sh fs --quiet --config /src/.trivy-license.yaml --ignorefile /src/.trivyignore-license.yaml \
	  --scanners license --severity CRITICAL,HIGH,UNKNOWN --exit-code 1 /src
```

- `go get -tool` (Go ≥ 1.24) ล็อกเวอร์ชัน templ/goose ใน go.mod — ไม่ใช้ `which X || go install` แบบต้นแบบ (เครื่องที่มีเวอร์ชันอื่นอยู่แล้วจะไม่ถูกเปลี่ยน)
- `templ generate && git diff --exit-code` กันลืม commit ไฟล์ `_templ.go`
- เพิ่ม `bin/` ใน `.gitignore`

## `.golangci.yml` (✚ SAST)

```yaml
version: "2"
linters:
  enable: [gosec, bodyclose, errorlint, noctx, sqlclosecheck]
  settings:
    gosec:
      excludes: []          # ปิด rule รายบรรทัดด้วย //nolint:gosec // <เหตุผล> เท่านั้น
formatters:
  enable: [gofmt, goimports]
```

## Dockerfile

```dockerfile
FROM golang:1.26-alpine AS builder
WORKDIR /src
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN go tool templ generate && CGO_ENABLED=0 go build -trimpath -ldflags="-w -s" -o /app/server ./cmd/server

FROM alpine:3.23 AS runner
RUN apk add --no-cache tzdata ca-certificates \
 && addgroup -g 1000 appuser && adduser -u 1000 -G appuser -D appuser \
 && mkdir -p /app/data /app/uploads && chown -R appuser:appuser /app
WORKDIR /app
COPY --from=builder --chown=appuser:appuser /app/server /app/server
USER appuser
EXPOSE 8080
HEALTHCHECK --interval=30s --timeout=5s --retries=3 CMD ["/app/server", "healthcheck"]
ENTRYPOINT ["/app/server"]
```

- `import _ "time/tzdata"` ใน main.go ด้วย (ทำงานแม้ image ไม่มี tzdata)
- pin alpine เป็น patch (`3.23.6`) ตอนใช้จริง
- `.dockerignore`: `.git`, `bin/`, `e2e/`, `.zap/`, `*.db`

## Health, shutdown (✚ `/readyz`)

```go
var ready atomic.Bool // true หลัง migrate สำเร็จ; false ทันทีเมื่อได้ SIGTERM

r.Get("/healthz", func(w http.ResponseWriter, r *http.Request) {
	writeJSON(w, http.StatusOK, map[string]string{"status": "ok"})
})
r.Get("/readyz", func(w http.ResponseWriter, r *http.Request) {
	ctx, cancel := context.WithTimeout(r.Context(), 2*time.Second)
	defer cancel()
	checks := map[string]string{"db": "ok", "migrations": "ok"}
	if err := database.PingContext(ctx); err != nil {
		checks["db"] = "fail"
	}
	if !ready.Load() {
		checks["migrations"] = "fail"
	}
	if checks["db"] != "ok" || checks["migrations"] != "ok" {
		writeJSON(w, http.StatusServiceUnavailable, map[string]any{"status": "unavailable", "checks": checks})
		return
	}
	writeJSON(w, http.StatusOK, map[string]string{"status": "ready"})
})
```

- router หลัก: `r.Use(middleware.GetHead)` ถัดจาก `middleware.Recoverer` — chi ไม่ map `HEAD` → `GET` ให้เอง ถ้าไม่ใส่ทุก route ตอบ `HEAD` เป็น 405 (itms-app #124)
- subcommand `healthcheck` เรียก `http://127.0.0.1:$PORT/readyz` (ต้นแบบเรียก `/healthz` ✚ เปลี่ยน)
- shutdown: `signal.NotifyContext(ctx, os.Interrupt, syscall.SIGTERM)` → `ready.Store(false)` → `server.Shutdown` timeout 10 วินาที; compose `stop_grace_period: 15s`

## SQLite + migration + seed

- DSN: `file:<path>?_pragma=journal_mode(WAL)&_pragma=busy_timeout(5000)&_pragma=foreign_keys(1)` และ `db.SetMaxOpenConns(1)` — SQLite เขียนได้ทีละคน; ตรวจสิทธิ์ที่ต้องอ่าน-แล้วเขียนใช้ transaction `BEGIN IMMEDIATE`
- migration: `goose.SetBaseFS(migrations.FS)` + `goose.Up(db, ".")` ตอน start ก่อนเปิดรับ request แล้วจึง `ready.Store(true)`
- seed: `/app/server seed` อ่านรหัสผ่านจาก env (`SEED_ADMIN_PASSWORD` …) ไม่มี default, idempotent (รันซ้ำไม่สร้างซ้ำ); e2e สุ่มรหัสผ่านทุกรอบ
- backup: `scripts/backup.sh` ของต้นแบบ (`sqlite3 .backup` + `integrity_check`, mount แบบเขียนได้ — `docs/backup.md`)

## compose

`compose.yml`, `compose.dev.yml`, `compose.prod.yml` ของต้นแบบใช้ได้ทันที (service `app`, port 8080, volume `app-data` + `app-uploads`, `TRUSTED_PROXIES`) — ✚ เพิ่ม `stop_grace_period: 15s`

## e2e และ DAST

- `compose.e2e.yml`: service `web` (`build: {context: ., target: runner}`, env ทดสอบ, healthcheck), `e2e` (`mcr.microsoft.com/playwright:v<ตรงกับ e2e/package.json>-noble`, profile `test`) และ ✚ `zap` (profile `dast`, `docs/testing.md`)
- `scripts/e2e.sh` ของต้นแบบ: สุ่มรหัสผ่าน → `up --wait web` → `exec web /app/server seed` → `up --no-start --no-deps e2e` + `docker cp` เข้า/ออก + `docker start -a` (ไม่ bind mount — `docs/testing.md` "CI runners") → `down -v --rmi local` เสมอ, project `-p <repo>-e2e-$$`

## i18n และ theme (✚)

- `go-i18n` โหลด `locales/*.json` ด้วย `embed`; middleware เลือกภาษาจาก cookie `locale` → `Accept-Language` → `th` แล้วใส่ localizer ใน context; templ เรียก `t(ctx, "ticket.status.open")`
- test: โหลดทุกไฟล์แปลแล้วเทียบชุด key ให้ตรงกัน
- theme: middleware อ่าน cookie `theme` ส่งให้ layout ใส่ `data-theme` บน `<html>`; CSS token ตาม `docs/ui.md`
- HTMX: session หมดอายุตอบ 401 + header `HX-Redirect: /login?next=<path>`

## กับดักที่เจอในต้นแบบ

- ต้อง commit ไฟล์ `*_templ.go` ที่ generate แล้ว ไม่งั้น `go build` ใน Docker พัง (หรือให้ Dockerfile รัน `templ generate` ตามสูตรนี้)
- HTMX + CDN: ✚ self-host `htmx.min.js` ใน `/static` แทน CDN (ZAP rule 90003 SRI + CSP `script-src 'self'`)
- seed ใน e2e ต้อง `exec` เข้า container ที่รันอยู่ — `run` แยกจะได้ DB คนละไฟล์

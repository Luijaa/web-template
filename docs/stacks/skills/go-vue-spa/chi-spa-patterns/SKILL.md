---
name: chi-spa-patterns
description: Use when adding or changing routes, middleware, health endpoints, JSON errors or the embedded Vue SPA serving in a Go + chi v5 app (go-vue-spa stack).
source: เขียนเองจาก https://pkg.go.dev/github.com/go-chi/chi/v5, https://pkg.go.dev/embed, RFC 9457, RFC 9110 (อ่านเมื่อ 2026-10-29) — ต้นแบบ pulse-app (`luija-dev/pulse-app` `6ec2cf0`)
---
# chi v5 + SPA ที่ embed ใน binary

ตรวจเวอร์ชัน chi ใน `go.mod` ก่อน — API ที่ไม่มีตัวอย่างใน repo ให้ดู `go doc github.com/go-chi/chi/v5.<Symbol>` (ไม่เขียนตามที่จำได้)

## 1. ลำดับ middleware

```go
r := chi.NewRouter()
r.Use(middleware.RequestID)
r.Use(middleware.Recoverer)
r.Use(middleware.GetHead)   // chi ไม่ map HEAD → GET ให้เอง ไม่ใส่ = HEAD ได้ 405 (.agents/rules/api.md)
r.Use(trustedProxy)         // แทน RemoteAddr จาก X-Forwarded-For เฉพาะเมื่อมาจาก TRUSTED_PROXIES
r.Use(securityHeaders)      // CSP, nosniff, frame-ancestors, Referrer-Policy, Permissions-Policy
```

- middleware ตรวจสิทธิ์ใส่ใน `r.Group`/`r.Route` ของ route ที่ต้อง login — ห้ามซ่อนปุ่มฝั่ง Vue แทนการตรวจฝั่ง server
- ค่าใน context ใช้ key type ของตัวเอง (`type ctxKey struct{}`) ไม่ใช่ string

## 2. API และ error

```go
r.Route("/api/v1", func(api chi.Router) {
	api.Get("/items", h.List)
	api.Post("/items", h.Create)
	api.Route("/items/{id}", func(item chi.Router) {
		item.Get("/", h.Get)
		item.Put("/", h.Update)
		item.Delete("/", h.Delete)
	})
})
r.Handle("/api/*", http.HandlerFunc(apiNotFound)) // ห้ามหลุดไปเจอ SPA fallback
```

- id จาก path: `chi.URLParam(r, "id")` แล้ว validate ทุกครั้ง; ตรวจว่าผู้ใช้มีสิทธิ์กับ id นั้น (review หมวด C)
- error ตอบ `application/problem+json` (`type`, `title`, `status`, `detail`, `code` ให้ UI แปล) — ห้ามส่ง `err.Error()` ของ DB/ระบบออกไป
- body: `http.MaxBytesReader` + `json.NewDecoder(...).DisallowUnknownFields()`

## 3. health

- `/healthz` ตอบ 200 เสมอ; `/readyz` ping DB ด้วย timeout 2 วินาที และ 503 เมื่อกำลังปิด — `{"status":"unavailable","checks":{"db":"fail"}}` บอกแค่ชื่อ check
- `cmd/server healthcheck` เรียก `/readyz` ของตัวเอง (Dockerfile/compose ใช้ subcommand นี้ ไม่มี curl ใน image)

## 4. เสิร์ฟ SPA

```go
// web/embed.go
//go:embed all:dist
var distFS embed.FS

func Dist() (fs.FS, error) { return fs.Sub(distFS, "dist") }
```

```go
func spa(dist fs.FS) http.HandlerFunc {
	files := http.FileServer(http.FS(dist))
	index, _ := fs.ReadFile(dist, "index.html")
	return func(w http.ResponseWriter, r *http.Request) {
		p := strings.TrimPrefix(path.Clean(r.URL.Path), "/")
		if p != "" && p != "index.html" {
			if f, err := dist.Open(p); err == nil {
				_ = f.Close()
				if strings.HasPrefix(p, "assets/") {
					w.Header().Set("Cache-Control", "public, max-age=31536000, immutable")
				}
				files.ServeHTTP(w, r)
				return
			}
		}
		w.Header().Set("Content-Type", "text/html; charset=utf-8")
		w.Header().Set("Cache-Control", "no-cache")
		_, _ = w.Write(index)
	}
}
r.Get("/*", spa(dist))
```

- `all:` ต้องมี — ไม่งั้นไฟล์ที่ขึ้นต้นด้วย `_`/`.` ใน dist หาย; `web/dist` ต้องถูก build ก่อน `go build`/`go test`/lint
- ไฟล์ใน `assets/` มี hash ในชื่อ cache ได้ยาว; `index.html` ห้าม cache (deploy ใหม่แล้วผู้ใช้ต้องได้ JS ชุดใหม่)

## 5. server และ shutdown

- `http.Server` ตั้ง `ReadHeaderTimeout`, `ReadTimeout`, `WriteTimeout`, `IdleTimeout` ทุกตัว
- `signal.NotifyContext(ctx, os.Interrupt, syscall.SIGTERM)` → ตั้งสถานะกำลังปิด → หยุดงานเบื้องหลัง → `srv.Shutdown(ctx)` timeout 10 วินาที
- งานเบื้องหลัง (ticker, worker) รับ `context` และหยุดเมื่อ context ถูกยกเลิก — test ด้วย `httptest` + context ที่ยกเลิกได้

## 6. test

- `httptest.NewRecorder()` + `router.ServeHTTP` ทดสอบผ่าน router จริง (รวม middleware) ไม่เรียก handler ตรง ๆ
- ทุก route ใหม่: `HEAD` ไม่ใช่ 405, path ใต้ `/api/` ที่ไม่มีจริงได้ 404 problem+json, security header อยู่ครบ

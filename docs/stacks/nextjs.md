# สูตร: Next.js (App Router, standalone) + Prisma + SQLite

> ต้นแบบ: oncall-app `cebbb75` (ผ่าน CI check/e2e/security/image, image คลาย ~600 MB (เกินค่าเริ่มต้น 150 MB บีบอัด), RAM ~50 MiB) — เวอร์ชัน ณ 14 ต.ค. 2026 ตรวจใหม่ก่อนใช้
> ✚ = ยังไม่มีในต้นแบบ ต้องเพิ่มตามกฎปัจจุบันของ template

## โครงสร้าง

```
web/                    แอป Next.js ทั้งหมด (CONTEXT=web, TARGET=runner ใน image.yml)
  src/app/              route (App Router) — /healthz, /readyz เป็น route.ts
  src/lib/              service (กฎสิทธิ์), prisma client, auth
  src/i18n/, messages/th.json, messages/en.json   ✚ next-intl
  prisma/schema.prisma, prisma/migrations/, prisma/seed.ts
  Dockerfile
e2e/                    Playwright
scripts/e2e.sh, scripts/dast.sh
```

## เวอร์ชันที่ใช้

| ส่วน | เวอร์ชัน | license | หมายเหตุ |
|---|---|---|---|
| Node | 24 LTS (`node:24.21.0-alpine`) | MIT | 26 เป็น LTS 28 ต.ค. 2026 → ยังใช้ 24 ตาม N-1 |
| Next.js | 16.x | MIT | 15 EOL 2026-10-21 → ใช้ 16 (ข้อยกเว้น N ใน `docs/dependencies.md`) |
| React | 19.x | MIT | |
| Prisma | 6.x | Apache-2.0 | CLI + tsx อยู่ใน `/opt/tools` ของ runner เพื่อ migrate/seed |
| next-auth | 4.x | ISC | |
| Tailwind | 4.x | MIT | สีผ่าน CSS variable ตาม `docs/ui.md` |
| Jest | 30.x | MIT | unit test |
| next-intl | 4.x | MIT | ✚ i18n แบบ ICU MessageFormat |
| eslint-plugin-security | ล่าสุดที่ ≥ 14 วัน | Apache-2.0 | ✚ SAST |

## Makefile

```make
COMPOSE ?= docker compose
TRIVY ?= docker run --rm -v /var/run/docker.sock:/var/run/docker.sock -v $(CURDIR):/src:ro aquasec/trivy:0.74.0
LICENSE_ARGS ?= --quiet --config /src/.trivy-license.yaml --ignorefile /src/.trivyignore-license.yaml \
	--scanners license --severity CRITICAL,HIGH,UNKNOWN --exit-code 1
IMAGE ?= $(shell $(COMPOSE) config --images)

setup:   ## install dependencies
	cd web && npm ci && npx prisma generate
lint:    ## lint + format check + SAST
	cd web && npm run lint && npx tsc --noEmit
test:    ## unit/integration tests
	cd web && npx jest --passWithNoTests
build:   ## build container images
	$(COMPOSE) build
e2e:     ## end-to-end tests on the production image
	./scripts/e2e.sh
dast:    ## ZAP baseline scan of the running production image
	./scripts/dast.sh
license: build ## open-source license check
	$(TRIVY) image $(LICENSE_ARGS) --pkg-types library $(IMAGE)
```

- ใช้ `npm ci` (ตาม lockfile) ไม่ใช่ `npm install` แบบต้นแบบ

## `eslint.config.mjs` (✚ SAST)

```js
import { defineConfig, globalIgnores } from "eslint/config";
import nextVitals from "eslint-config-next/core-web-vitals";
import nextTs from "eslint-config-next/typescript";
import security from "eslint-plugin-security";

export default defineConfig([
  ...nextVitals,
  ...nextTs,
  security.configs.recommended,
  globalIgnores([".next/**", "out/**", "build/**", "next-env.d.ts"]),
]);
```

## Dockerfile (ย่อจากต้นแบบ — ใช้ไฟล์ต้นแบบเต็ม)

stage: `base` (node alpine + `openssl libc6-compat tzdata`) → `deps` (`npm ci` + `prisma generate`) → `builder` (`next build`, `output: "standalone"`) → `tools` (prisma + tsx + ที่ seed ต้องใช้ **เวอร์ชันเดียวกับ package-lock** ใน `/opt/tools`) → `runner`:

- คัดลอก `.next/standalone`, `.next/static`, `public`, `prisma`, `/opt/tools`
- ลบ `npm`, `npx`, `corepack` ออกจาก runner (ลดขนาด + ลดช่องโหว่)
- `USER node`, `HEALTHCHECK CMD wget -qO- http://127.0.0.1:3000/readyz || exit 1` (✚ ต้นแบบเรียก `/healthz`)
- `CMD ["sh", "-c", "prisma migrate deploy && exec node server.js"]` — ต้องมี `exec` ไม่งั้น `sh` เป็น PID 1 และไม่ส่ง SIGTERM ต่อให้ node (graceful shutdown ไม่ทำงาน, `docker stop` รอจนครบ grace period แล้ว kill)

## Health (✚ `/readyz`)

```ts
// src/app/readyz/route.ts
import { prisma } from "@/lib/prisma";
export const dynamic = "force-dynamic";
export async function GET() {
  try {
    await Promise.race([
      prisma.$queryRaw`SELECT 1`,
      new Promise((_, reject) => setTimeout(() => reject(new Error("timeout")), 2000)),
    ]);
    return Response.json({ status: "ready" });
  } catch {
    return Response.json({ status: "unavailable", checks: { db: "fail" } }, { status: 503 });
  }
}
```

`/healthz` ตอบ `{"status":"ok"}` โดยไม่แตะ DB; middleware ต้องยกเว้นทั้งสอง path จาก auth

**ยังขาด (✚ ต้องทำเองตอนตั้ง stack — ยังไม่ได้ทดสอบในโปรเจกต์จริง):** กฎ `.agents/rules/api.md` ให้ `/readyz` ตอบ 503 ทันทีที่ได้ SIGTERM แล้วค่อยปิด
แต่ server ของ Next.js standalone จัดการ SIGTERM เองและปิดทันที — ต้องตั้ง env `NEXT_MANUAL_SIG_HANDLE=true` แล้วจัดการเองใน `instrumentation.ts`
(ตั้ง flag ที่ `/readyz` อ่าน → รอ request ค้าง ≤ 10 วินาที → `process.exit(0)`) ตามหัวข้อ graceful shutdown ใน [Next.js self-hosting guide](https://nextjs.org/docs/app/guides/self-hosting)
— ตรวจกับเอกสารของเวอร์ชันที่ใช้ และเขียน e2e/integration test ยืนยันก่อนใช้จริง

## migration + seed

- `prisma migrate dev --name <ชื่อ>` ตอนพัฒนา → commit `prisma/migrations/`; production รัน `prisma migrate deploy` ตอน start
- seed: `docker compose exec web tsx prisma/seed.ts` อ่าน `SEED_ADMIN_PASSWORD` จาก env, idempotent (`upsert`)

## i18n และ theme (✚)

- `next-intl` แบบไม่มี prefix ภาษาใน URL (แอปภายใน): อ่าน cookie `locale` → `Accept-Language` → `th` ใน `src/i18n/request.ts`; ข้อความใน `messages/th.json`, `messages/en.json`
- test: เทียบชุด key ของทุกไฟล์ใน `messages/`
- theme: อ่าน cookie `theme` ใน root layout (server component) แล้วใส่ `data-theme` บน `<html>` — ไม่ต้องใช้ library theme และไม่มี inline script
- `Intl.DateTimeFormat("th-TH-u-ca-<buddhist|gregory>", { timeZone: "Asia/Bangkok" })` ตาม ADR

## กับดักที่เจอในต้นแบบ

- healthcheck ใช้ `127.0.0.1` ไม่ใช่ `localhost` — alpine แปลง localhost เป็น `::1` แต่ standalone server ฟัง IPv4
- เวอร์ชัน prisma ใน `/opt/tools` เคยว่างเพราะ quote หายตอนส่งคำสั่งผ่าน ssh → npm ลง prisma รุ่นใหม่สุด — Dockerfile ต้นแบบ `test -n` และเทียบเวอร์ชันแล้ว fail ถ้าไม่ตรง
- image ใหญ่ (~600 MB) เพราะ prisma engine + sharp — เกินค่าเริ่มต้น 150 MB ต้องเขียนเหตุผลใน ADR หรือเลือกสูตร Go
- `docker compose run` ใน e2e ต้อง `--no-deps` ไม่งั้น CI recreate `web` แล้ว DB ว่าง

# สูตรตาม stack (stack recipes)

> ประเภทเอกสาร: **how-to** — ตั้ง `Makefile`, Dockerfile, compose, health, migration/seed, e2e และ SAST ให้ผ่านกฎของ template ตั้งแต่วันแรก

ทุกสูตรสกัดจากโปรเจกต์ที่ผ่าน CI ครบแล้วจริง (ไม่ได้เขียนขึ้นใหม่จากศูนย์) และระบุสิ่งที่ต้อง**เพิ่ม**ตามกฎที่ออกทีหลังโปรเจกต์ต้นแบบ

| สูตร | ต้นแบบ | เหมาะกับ |
|---|---|---|
| [`go-templ-htmx.md`](go-templ-htmx.md) | itms-app (`luija-dev/itms-app`, `879eda6`) | แอปภายในองค์กร server-rendered, image บีบอัด ~10 MB, RAM ~11 MiB |
| [`nextjs.md`](nextjs.md) | oncall-app (`luija-dev/oncall-app`, `cebbb75`) | UI โต้ตอบเยอะ, ทีมถนัด React — image ~600 MB เกินค่าเริ่มต้น |

## วิธีใช้

1. เลือก stack ใน ADR-0001 (`docs/design-process.md` กิ่ง C) — สูตรเป็นจุดเริ่ม ไม่ใช่ข้อบังคับ
2. **เวอร์ชันในสูตรเป็นของ ณ วันที่เขียน** — ก่อนใช้ตรวจใหม่ทุกตัวตาม `docs/dependencies.md` (แกนหลัก N-1 + EOL, library ≥ 14 วัน, license)
3. คัดลอกไฟล์ตามสูตร แทนที่ recipe `not configured` ใน `Makefile` ทุก target (`setup`, `lint`, `test`, `e2e`, `dast`, `license`) และแก้ `CONTEXT`/`TARGET` ใน `.github/workflows/image.yml`
4. `make check`, `make e2e`, `make dast` ต้องผ่านใน PR scaffold — CI ข้าม job ที่ยัง `not configured` เท่านั้น
5. อัปเดตตาราง container ใน `docs/architecture.md`
6. ติดตั้ง skill ของ stack: คัดลอก `skills/<stack>/*` ไป `.agents/skills/` (หัวข้อ "skill ของ stack" ในแต่ละสูตร) — stack ที่ยังไม่มีชุดสำเร็จรูป เขียนตามชุดที่อนุมัติใน ADR-0001 แล้วส่งกลับมาเก็บที่ `skills/<stack>/`

## สิ่งที่ทุกสูตรต้องมี (เช็คก่อนเปิด PR scaffold)

| เรื่อง | กฎ |
|---|---|
| Dockerfile multi-stage, non-root, base pin N-1, multi-arch, `tzdata` | `.agents/rules/container.md` |
| `HEALTHCHECK` เรียก `/readyz`; มี `/healthz` แยก; graceful shutdown | `.agents/rules/api.md` |
| migration รันตอน start, ไฟล์ใหม่ทุกครั้ง; seed แยกเป็นคำสั่ง ใช้รหัสผ่านจาก env | `.agents/rules/api.md` |
| `make lint` มี SAST | `docs/testing.md` |
| `make e2e` / `make dast` ใช้ `compose.e2e.yml` + project name ไม่ซ้ำต่อรัน | `docs/testing.md` |
| i18n `th`/`en` + theme token ตั้งแต่หน้าแรก | `docs/ui.md` |
| `TRUSTED_PROXIES`, session timeout, audit log, security header | `.agents/rules/api.md` |
| compose ทุกไฟล์มี `TZ`, limit, healthcheck; `compose.prod.yml` ตรงกับ `compose.yml` | `.agents/rules/container.md` |

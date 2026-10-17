---
paths:
  - "**/Dockerfile"
  - "**/Dockerfile.*"
  - "compose*.yml"
  - ".github/workflows/**"
---
# Container & CI rules

- Dockerfile: multi-stage, base image pin ด้วย tag เวอร์ชัน (ห้าม `latest`) และเป็นสาย N-1 ตาม `docs/dependencies.md`, รันด้วย user ที่ไม่ใช่ root, มี HEALTHCHECK
- ห้ามใส่ secret ใน image หรือ build arg — ส่งผ่าน env ตอนรัน
- เขตเวลา: ทุก service ใน compose ทุกไฟล์ (dev/prod/e2e) ตั้ง `environment: TZ: Asia/Bangkok` ไว้ในไฟล์ compose ไม่ใช่ใน `.env` และ image ต้องมีข้อมูล timezone: alpine `apk add --no-cache tzdata`, Go `import _ "time/tzdata"`, Python ติด package `tzdata` — ตรวจ: image ที่มี shell `docker run --rm -e TZ=Asia/Bangkok <image> date` ต้องได้ `+07`; image scratch/distroless ให้แอปโหลด Asia/Bangkok ตอนเริ่ม ถ้าไม่ได้ให้หยุดทำงาน
- compose: ทุก service มี resource limit (`cpus`, `mem_limit`), `restart: unless-stopped`, healthcheck ที่เรียก **`/readyz`** (ให้ `up --wait` และ `depends_on: service_healthy` หมายถึงพร้อมใช้จริง) — image ที่ไม่มี shell/wget ให้แอปมี subcommand เช่น `/app/server healthcheck` ที่เรียก `/readyz`; k8s: `livenessProbe` → `/healthz`, `readinessProbe`/`startupProbe` → `/readyz`; `stop_grace_period` ≥ เวลา graceful shutdown ของแอป
- dev deploy: ต่อ network ภายนอกของ reverse proxy (ดู compose.dev.yml) ห้าม publish port ออก 0.0.0.0
- `TRUSTED_PROXIES` (ดู `.agents/rules/api.md`): ใส่**เฉพาะ** subnet/IP ของ reverse proxy ที่ต่อเข้าแอป — dev ใช้ subnet ของ `npm-net` (`docker network inspect npm-net -f '{{(index .IPAM.Config 0).Subnet}}'`) ตั้งไว้ใน `compose.dev.yml`; production ตั้งใน `.env` ตาม `docs/deploy-prod.md`; **ห้ามใส่วง LAN ของผู้ใช้หรือวงกว้าง** (`10.0.0.0/8`, `172.16.0.0/12`, `192.168.0.0/16`, `0.0.0.0/0`) — ผู้ใช้ทั้งองค์กรจะถูกนับเป็น IP เดียว (ล็อกทั้งระบบ) หรือปลอม IP ข้าม rate limit ได้; ไม่มี proxy = เว้นว่าง
- image ต้อง build ได้ทั้ง `linux/amd64` และ `linux/arm64` (dev เป็น ARM, production มีทั้งสองแบบ) — base image ต้องเป็น multi-arch, ห้ามดาวน์โหลด binary ที่ผูก arch ตายตัว
- image ควรเล็ก (พื้นที่ GHCR จำกัด): multi-stage, runner stage มีแค่สิ่งที่ต้องรัน
- image ตาม OCI Image Spec: label `org.opencontainers.image.*` (source, revision, version, created …) มาจาก `docker/metadata-action` ใน `image.yml` — ห้ามลบหรือแทนด้วย label เขียนมือ (`source` ใช้ผูก package กับ repo, `revision` ใช้ไล่ว่า image มาจาก commit ไหน); release เติม annotation `version` ที่ index (`docs/release.md`), แอป log ออก stdout/stderr ไม่เขียนไฟล์ log ใน container, ข้อมูลถาวรอยู่ใน volume เท่านั้น
- `compose.prod.yml` ใช้ `image:` จาก GHCR เท่านั้น ห้ามมี `build:`; แก้ service ใน compose.yml เมื่อไรต้องแก้ compose.prod.yml ให้ตรงกันใน PR เดียวกัน
- `.github/workflows/image.yml`: ตั้ง `CONTEXT`/`TARGET` ให้ตรงกับ Dockerfile จริง ห้ามเพิ่มการ push image จากที่อื่น
- e2e: `compose.e2e.yml` ใช้ Dockerfile target เดียวกับ production; tag image Playwright ต้องตรงกับ `@playwright/test` ใน `e2e/package.json`
- CI เรียกผ่าน `make` target เท่านั้น เพื่อให้ผลตรงกับที่รันในเครื่อง
- action ภายนอกใน workflow ให้ pin major version ล่าสุดที่ Dependabot เสนอ (ระบบ cooldown 14 วัน — เช่น `actions/checkout@v7`) ห้าม `@main`/`@master`/ไม่มี tag, อัปเกรดผ่าน PR ของ Dependabot เท่านั้น และให้ permission น้อยที่สุด

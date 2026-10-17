# Release: เวอร์ชันและ CHANGELOG

เลขเวอร์ชันตาม [Semantic Versioning 2.0.0](https://semver.org/spec/v2.0.0.html), `CHANGELOG.md` ตาม [Keep a Changelog 1.1.0](https://keepachangelog.com/en/1.1.0/)
**คนเป็นผู้สร้าง release/tag เท่านั้น** — agent เตรียม CHANGELOG ได้ แต่ห้ามสร้าง tag/release

## เลขเวอร์ชัน `MAJOR.MINOR.PATCH`

| เพิ่ม | เมื่อ | ตัวอย่าง |
|---|---|---|
| **MAJOR** | ของเดิมใช้ไม่ได้ถ้าไม่ทำอะไรเพิ่ม | ลบ/เปลี่ยน endpoint หรือรูปแบบ response ที่ระบบอื่นเรียก, เปลี่ยนชื่อหรือลบตัวแปร env, migration ที่ย้อนกลับไม่ได้หรือต้องทำมือ, ลบบทบาท/สิทธิ์ |
| **MINOR** | เพิ่มความสามารถ ของเดิมยังใช้ได้ | หน้าใหม่, endpoint ใหม่, ตัวแปร env ใหม่ที่มีค่าเริ่มต้น, migration ที่เพิ่มอย่างเดียว |
| **PATCH** | แก้บั๊ก/ปรับเล็กน้อย ไม่เพิ่มความสามารถ | แก้ข้อความ UI, แก้บั๊ก, อัปเดต dependency ที่ไม่เปลี่ยนพฤติกรรม, แก้ช่องโหว่ |

- ใช้ข้อที่สูงสุดของทุก PR ใน release นั้น (มี MINOR 1 ข้อ + PATCH 5 ข้อ = MINOR)
- เพิ่มเลขหลักไหน หลักที่ต่ำกว่ารีเซ็ตเป็น 0 (`1.4.2` → `1.5.0`)
- ก่อน `1.0.0` (ยังไม่ขึ้น production จริง) MINOR เปลี่ยนแบบ breaking ได้ — release แรกที่ใช้จริงคือ `1.0.0`
- tag เป็น `vX.Y.Z`, image เป็น `:X.Y.Z` (ไม่มี `v`) — `APP_VERSION` ใน `.env` ของ production ก็ไม่มี `v`
- ห้ามใช้เลขซ้ำ ห้ามลบ/ย้าย tag ที่ปล่อยแล้ว — ปล่อยผิดให้ออกเวอร์ชันใหม่

## หัวข้อ "CHANGELOG" ใน PR (ทุก PR)

ทุก PR เขียนผลต่อผู้ใช้ไว้ในหัวข้อ `## CHANGELOG` ของ PR description (มีใน template แล้ว) — **ไม่แก้ `CHANGELOG.md` ใน PR งานปกติ** เพราะหลาย agent ทำคู่ขนานจะชนกันที่บรรทัดเดียวกันทุกครั้ง

```
## CHANGELOG
Fixed: ผู้แจ้งเห็นใบแจ้งซ่อมของคนอื่นในหน้าค้นหา
```

- หมวด: `Added` `Changed` `Deprecated` `Removed` `Fixed` `Security` — 1 PR มีได้หลายบรรทัด
- เขียนเป็นภาษาไทยจากมุมผู้ใช้/ผู้ดูแลระบบ ("ช่างกรองใบแจ้งซ่อมตามสถานะได้") ไม่ใช่มุมโค้ด ("add filter param to handler")
- ใช้คำตาม `CONTEXT.md`
- PR ที่ไม่มีผลต่อผู้ใช้หรือผู้ดูแล (test, CI, refactor, เอกสารภายใน) ใส่ `-`
- เปลี่ยนที่ผู้ดูแล production ต้องทำอะไร (ตัวแปร env ใหม่, migration ช้า, ต้อง backup พิเศษ) ต้องเขียนบอกตรง ๆ

## เตรียม release (การ์ด writer 1 ใบต่อ release)

1. `make release-draft` (= `python3 scripts/prepare-release.py [--since vX.Y.Z]`, ต้องมี `gh`) — ดึงหัวข้อ CHANGELOG ของทุก PR ที่ merge ตั้งแต่ release ล่าสุด จัดตามหมวด เสนอเลขเวอร์ชัน และพิมพ์ลิงก์ท้ายไฟล์ให้ **พิมพ์ออกจออย่างเดียว ไม่แก้ไฟล์**; PR ที่ไม่มีหัวข้อ CHANGELOG อยู่ในกลุ่ม "ต้องตรวจเอง" — อ่าน diff แล้วตัดสินเอง
2. ตรวจเลขเวอร์ชันที่เสนอกับตารางด้านบน แล้วใส่เหตุผล 1 บรรทัดใน PR (คนตัดสินเลขสุดท้าย)
3. แก้ `CHANGELOG.md` ใน PR เดียว ชื่อ `docs: CHANGELOG for vX.Y.Z`:
   - เพิ่ม `## [X.Y.Z] - YYYY-MM-DD` (วันที่ตามเวลาไทย) ใต้ `## [Unreleased]` ซึ่งคงไว้บนสุดและว่าง
   - จัดตามหมวด เรียง `Added`, `Changed`, `Deprecated`, `Removed`, `Fixed`, `Security` ข้ามหมวดที่ไม่มี
   - รวมบรรทัดที่พูดเรื่องเดียวกันเป็นข้อเดียว; ท้ายแต่ละข้ออ้าง issue/PR แบบลิงก์อ้างอิง `([#58], [#59])`
   - ลิงก์ท้ายไฟล์: `[Unreleased]` → `compare/vX.Y.Z...HEAD`, `[X.Y.Z]` → `compare/v<ก่อนหน้า>...vX.Y.Z` (release แรก → `releases/tag/vX.Y.Z`), เพิ่ม `[#N]` ที่ใช้ใหม่เรียงตามเลข
   - **ห้ามแก้เนื้อหาของเวอร์ชันที่ปล่อยแล้ว** (ยกเว้นลิงก์/คำผิด) และห้ามเขียนสิ่งที่ไม่มีในโค้ดจริง
4. reviewer ตรวจว่าทุก PR ในช่วงนั้นมีอยู่ครบ (หรือเป็น `-`) และเลขเวอร์ชันตรงตามตาราง
5. คน merge → CI `ci` และ `image` บน `main` เขียว → สร้าง release (ด้านล่าง)

## สร้าง release (คนทำ)

1. ทดสอบบน dev ให้ผ่าน (dev รัน `:main` ล่าสุด ซึ่งรวม CHANGELOG แล้ว)
2. GitHub → Releases → Draft a new release
   - tag `vX.Y.Z`, target `main`
   - title `vX.Y.Z`
   - notes: คัดลอกหัวข้อ `[X.Y.Z]` จาก `CHANGELOG.md` (ไม่ต้องกด Generate release notes)
3. Publish → รอ workflow `image` เขียว → มี `:X.Y.Z` และ `:latest` ใน Packages
4. deploy production ตาม `docs/deploy-prod.md`

## SBOM และ provenance

ทุก image ที่ CI push มี attestation 2 อย่างติดอยู่ใน GHCR ข้าง image (ไม่ต้องทำอะไรเพิ่มตอน release — retag แล้วยังอยู่):

- **SBOM** (SPDX 2.3, สร้างโดย BuildKit) — รายการ package ทั้งหมดใน image
- **provenance** (SLSA v1) — build จาก repo/commit/workflow ไหน (`mode=min` ไม่เก็บค่า build-arg)

```bash
IMG=ghcr.io/{{GITHUB_ORG}}/{{PROJECT_NAME}}:1.2.3
docker buildx imagetools inspect $IMG --format '{{ json (index .SBOM "linux/amd64").SPDX }}' > sbom-amd64.spdx.json
docker buildx imagetools inspect $IMG --format '{{ json (index .Provenance "linux/amd64").SLSA }}'
# ลูกค้าขอ CycloneDX: สร้างจาก image ด้วย trivy (ต้อง docker login ghcr.io ก่อนถ้า repo private)
docker run --rm -v ~/.docker/config.json:/root/.docker/config.json:ro aquasec/trivy:0.74.0 image --format cyclonedx $IMG > sbom.cdx.json
# ตรวจช่องโหว่ของเวอร์ชันที่ปล่อยไปแล้ว จาก SBOM โดยไม่ต้องดึง image
docker run --rm -v "$PWD:/w" aquasec/trivy:0.74.0 sbom /w/sbom-amd64.spdx.json
```

## image มาจาก commit/เวอร์ชันไหน

- label ใน image (ตั้งด้วย `docker/metadata-action` ตอน build บน main): `org.opencontainers.image.revision` = commit เต็ม, `version` = `sha-<7>`, `created`, `source`, `licenses` …
- release ไม่ build ใหม่: `:X.Y.Z` ใช้ manifest ของแต่ละ platform ตัวเดิมของ `:sha-<7>` แต่ index ใหม่มี annotation `org.opencontainers.image.version=X.Y.Z` (digest ของ `:X.Y.Z` จึงต่างจาก `:sha-<7>` แต่ digest ราย platform เท่ากัน)

```bash
docker buildx imagetools inspect $IMG --format '{{ json .Manifest.Annotations }}'                        # version ของ release
docker buildx imagetools inspect $IMG --format '{{ json (index .Image "linux/amd64").Config.Labels }}'   # revision, version=sha-<7>
```

ระดับ: SLSA Build L1 (provenance มีแต่ยังไม่ได้เซ็น) — ถึง L2 เมื่อเพิ่มการเซ็นด้วย cosign (ยังไม่ทำ)

# Dependencies: เวอร์ชันและ license

ใช้ทุกครั้งที่เลือก stack, เพิ่ม dependency, เปลี่ยน base image หรือรับ PR ของ Dependabot
ผลการเลือกแกนหลัก (runtime, framework, DB) บันทึกเป็น ADR ใน `docs/adr/`; dependency อื่นบอกใน PR description

## เวอร์ชัน

### แกนหลัก — สาย N-1

แกนหลัก = runtime (Node, Go, Python), framework หลักของแอป (Next.js, FastAPI, …), DB server (PostgreSQL, …) และ base image ของมัน

- **สาย** = major (Node, Next.js, PostgreSQL) หรือ minor สำหรับโปรเจกต์ที่ใช้ minor เป็นสาย (Go 1.x, Python 3.x)
- เลือก **สาย N-1** (รองจากสาย stable ล่าสุด) และใช้ **patch ล่าสุด**ของสายนั้นเสมอ
- runtime ที่มี LTS (Node): ใช้ LTS ใหม่สุดที่ไม่ใช่สาย N
- **ข้อยกเว้น → ใช้สาย N**: สาย N-1 EOL แล้วหรือเหลืออายุน้อยกว่า 3 เดือน, หรือโปรเจกต์มีสายเดียวที่ยังดูแล — เขียนเหตุผลเป็น ADR
- อยู่ต่อได้จนสายที่ใช้เหลืออายุ 3 เดือน แล้วเปิด issue ย้ายไปสาย N-1 ณ ตอนนั้น
- ตรวจ EOL: `curl -sL https://endoflife.date/api/<product>.json` (เช่น `nodejs`, `go`, `python`, `nextjs`, `postgresql`, `alpine`, `debian`) — ใช้กับ**ทุก `FROM` ทุก stage** และ `image:` ใน compose ด้วย; reviewer ใส่ตาราง image:tag | สาย | สาย N | วัน EOL ใน PR

ตัวอย่าง ณ 13 ต.ค. 2026:

| แกน | สาย N | ใช้ | หมายเหตุ |
|---|---|---|---|
| Node | 26 | **24 LTS** | EOL 2028-04 |
| Go | 1.27 | **1.26** | EOL เมื่อ 1.28 ออก (~ก.พ. 2027) |
| Python | 3.15 | **3.14** | EOL 2030-10 |
| PostgreSQL | 18 | **17** | EOL 2029-11 |
| Next.js | 16 | **16** (ข้อยกเว้น) | 15 EOL 2026-10-21 |

### library อื่น — stable ล่าสุดที่ออกมาแล้ว ≥ 14 วัน

- ห้าม pre-release: `alpha` `beta` `rc` `canary` `next` `preview` `nightly` และ npm dist-tag ที่ไม่ใช่ `latest`
- รุ่นที่ออกไม่ถึง 14 วัน ให้ใช้รุ่นก่อนหน้า (กัน package ถูกยึดแล้วปล่อยรุ่นปลอม) — ยกเว้นรุ่นที่แก้ช่องโหว่ ใช้ได้ทันที
- `0.x` ใช้ได้ถ้าเป็นสายเดียวของโปรเจกต์นั้น
- ต้องยังมีคนดูแล: release หรือ commit ใน 12 เดือน, repo ไม่ archived
- pin เวอร์ชันจริงด้วย lockfile (`package-lock.json`, `go.sum`, `uv.lock`/`requirements.txt` แบบ `==`) และ base image ด้วย tag เวอร์ชัน (ห้าม `latest`)

## License

ใช้กับทุกอย่างที่อยู่ใน image หรือส่งให้ผู้ใช้ (รวม dependency ทางอ้อม) และโค้ด/ฟอนต์/ไอคอน/skill ที่คัดลอกมา

| กลุ่ม | license | ทำอย่างไร |
|---|---|---|
| ใช้ได้ | MIT, ISC, BSD-2/3-Clause, 0BSD, Apache-2.0, Zlib, BlueOak-1.0.0, Python-2.0, MPL-2.0 (ไม่แก้ไฟล์ของเขา), Unlicense, CC0-1.0, CC-BY-4.0 / OFL-1.1 (เอกสาร, ฟอนต์) | ใช้ได้เลย |
| ต้องขออนุมัติ | LGPL-2.1/3.0, EPL-2.0, CDDL-1.0 | บันทึก ADR (ทำไม, link แบบไหน) + ใส่ใน `.trivyignore-license.yaml` |
| ห้าม | GPL-2.0/3.0, AGPL-3.0, SSPL-1.0, BUSL-1.1, Elastic-2.0, CC-BY-NC*, ไม่มี license, license ที่เขียนเอง/ไม่รู้จัก | หาตัวอื่น |

- เครื่องมือที่ใช้ตอน dev/CI เท่านั้นและไม่อยู่ใน image (linter, test runner): ห้ามเฉพาะ "ไม่มี license" และ "ห้ามใช้เชิงพาณิชย์"
- LGPL: dynamic link (เช่น shared library แยกไฟล์) มักรับได้; static link (Go binary) ไม่ได้
- รายการเต็มที่ใช้ตรวจอยู่ใน `.trivy-license.yaml` — แก้ตารางนี้ต้องแก้ไฟล์นั้นด้วย

### ตรวจอัตโนมัติ: `make license`

CI รันใน job `check` หลัง `make build` — fail เมื่อเจอ license ที่ห้าม (CRITICAL), ต้องขออนุมัติแต่ยังไม่ได้ยกเว้น (HIGH), หรือไม่รู้จัก (UNKNOWN)

ตั้งตอนเลือก stack (แทน recipe `not configured` ใน Makefile) — วิธีสแกนทั้งสองแบบทดสอบแล้วกับ trivy 0.74.0 (13 ต.ค. 2026) ส่วน recipe ให้ปรับชื่อ image/path ตามโปรเจกต์:

```make
TRIVY = docker run --rm -v /var/run/docker.sock:/var/run/docker.sock -v $(CURDIR):/src:ro aquasec/trivy:0.74.0
LICENSE_ARGS = --quiet --config /src/.trivy-license.yaml --ignorefile /src/.trivyignore-license.yaml \
	--scanners license --severity CRITICAL,HIGH,UNKNOWN --exit-code 1

# Node / Python: สแกน image ที่ build แล้ว (อ่าน license จาก node_modules / site-packages)
license: build
	$(TRIVY) image $(LICENSE_ARGS) --pkg-types library <image ที่ make build สร้าง>

# Go: binary ไม่มีข้อมูล license — สแกน go.mod พร้อม module cache แทน
license:
	go mod download
	docker run --rm -e GOPATH=/gopath -v $(CURDIR):/src:ro -v $$(go env GOPATH):/gopath:ro \
	  aquasec/trivy:0.74.0 fs $(LICENSE_ARGS) /src
```

ตรวจว่า target จับได้จริง: เพิ่ม package GPL ชั่วคราวแล้ว `make license` ต้อง fail

ยกเว้นราย package (เฉพาะกลุ่ม "ต้องขออนุมัติ" ที่มี ADR แล้ว) ใน `.trivyignore-license.yaml`:

```yaml
licenses:
  - id: LGPL-3.0-or-later
    paths: ["app/node_modules/@img/sharp-*/package.json"]   # glob ได้
    statement: "ADR-000N: libvips dynamic link ผ่าน sharp"
    expired_at: 2027-04-30
```

## Dependabot

- PR ของ Dependabot ทำตามนโยบายนี้: รอ 14 วันหลัง release (`cooldown`), ไม่เสนอ major ของแกนหลัก — ย้ายสายแกนหลักทำเป็นงานแยกพร้อม ADR
- PR แก้ช่องโหว่ (security update) ไม่ต้องรอ cooldown

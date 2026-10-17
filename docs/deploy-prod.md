# Deploy production

image ถูก build ครั้งเดียวใน GitHub Actions (`.github/workflows/image.yml`) แล้วใช้ตัวเดียวกันทั้ง dev และ production
production รันจาก image ใน GHCR เท่านั้น — ไม่มีซอร์สโค้ด ไม่ build บนเครื่อง production

| เหตุการณ์ | image ที่ได้ | ใช้ที่ |
|---|---|---|
| merge เข้า `main` | `ghcr.io/{{GITHUB_ORG}}/{{PROJECT_NAME}}:sha-<7>`, `:main` | dev |
| GitHub Release `v1.2.3` | `:1.2.3`, `:latest` (ติด tag ให้ image ของ commit นั้น ไม่ build ใหม่) | production |

ทุก image เป็น multi-arch (`linux/amd64` + `linux/arm64`) ใช้ได้ทั้งเครื่อง x86 และ ARM

## ปล่อยเวอร์ชัน (คนทำเท่านั้น — agent ห้ามสร้าง release/tag)

เลขเวอร์ชัน, การเตรียม `CHANGELOG.md` และขั้นตอนกด Release อยู่ใน [`docs/release.md`](release.md) — merge PR CHANGELOG ก่อนสร้าง release ทุกครั้ง
หลังกด Publish รอ workflow `image` job `release` เขียว → มี `:1.2.3` ใน Packages ของ repo

## เตรียมเครื่อง production (ครั้งแรก)

```bash
# 1. Docker Engine + compose plugin
# 2. login GHCR ด้วย classic PAT ที่มีสิทธิ์ read:packages อย่างเดียว (GHCR ไม่รองรับ fine-grained token)
docker login ghcr.io -u <github-user>
# 3. วางไฟล์ 2 ไฟล์ในโฟลเดอร์เดียว เช่น /opt/{{PROJECT_NAME}}
#    compose.prod.yml  (จาก repo)
#    .env              (จาก .env.example — ใส่ค่าจริง, chmod 600, ห้าม commit)
chmod 600 .env
```

เขตเวลาของแอปตั้งไว้ใน `compose.prod.yml` (`TZ: Asia/Bangkok`) — ไม่ขึ้นกับ timezone ของเครื่อง production

ใน `.env` ต้องมี `APP_VERSION=1.2.3` (ไม่มี `v`) และค่าลับของแอป (สร้างใหม่สำหรับ production อย่าใช้ค่าจาก dev)

## Reverse proxy และ `TRUSTED_PROXIES`

production ควรมี reverse proxy ที่ทำ TLS อยู่หน้าแอป (nginx, Caddy, NPM, Traefik) แอปจึงเห็น IP ของ proxy แทน IP ผู้ใช้ — แอปอ่าน IP จริงจาก `X-Forwarded-For` **เฉพาะเมื่อ request มาจาก IP ใน `TRUSTED_PROXIES`**

| ตั้งแบบนี้ | ผล |
|---|---|
| subnet/IP ของ proxy เท่านั้น เช่น `127.0.0.1/32` (proxy บนเครื่องเดียวกันที่ต่อผ่าน port localhost) หรือ subnet ของ docker network ที่ proxy ใช้ (`docker network inspect <network>`) | ถูกต้อง |
| เว้นว่าง | ใช้ได้เมื่อไม่มี proxy — ถ้ามี proxy แต่เว้นว่าง ผู้ใช้ทุกคนจะเป็น IP ของ proxy (rate limit ล็อกทั้งองค์กร) |
| วง LAN ของผู้ใช้หรือวงกว้าง (`10.0.0.0/8`, `172.16.0.0/12`, `192.168.0.0/16`, `0.0.0.0/0`) | **ห้าม** — ผู้ใช้ใน LAN จะถูกนับเป็น IP เดียวกัน หรือส่ง `X-Forwarded-For` ปลอมเพื่อข้าม rate limit ได้ |

proxy ต้องส่ง `X-Forwarded-For` และ `X-Forwarded-Proto` ต่อให้แอป และตั้ง HSTS (`Strict-Transport-Security: max-age=31536000`) — ตรวจหลัง deploy ว่า log ของแอปเห็น IP ผู้ใช้จริง ไม่ใช่ IP ของ proxy
ตั้ง `APP_BASE_URL` เป็น URL https ที่ผู้ใช้เข้าจริง

## Deploy / อัปเกรด

```bash
cd /opt/{{PROJECT_NAME}}
sed -i 's/^APP_VERSION=.*/APP_VERSION=1.2.3/' .env
docker compose -f compose.prod.yml pull
docker compose -f compose.prod.yml up -d
docker compose -f compose.prod.yml ps        # ต้อง healthy (healthcheck เรียก /readyz)
```

database migration รันตอน container start — backup ก่อนอัปเกรดทุกครั้ง

## Rollback

ตั้ง `APP_VERSION` กลับเป็นเวอร์ชันก่อนหน้าแล้ว `pull` + `up -d` เหมือนเดิม
ถ้าเวอร์ชันใหม่ migrate database ไปแล้ว ให้ restore backup ก่อน rollback

## Backup

volume `app-data` เก็บข้อมูลทั้งหมด (เช่น SQLite, ไฟล์อัปโหลด) — ทำตาม [`docs/backup.md`](backup.md): backup วันละครั้งด้วยวิธีที่ได้ฐานข้อมูลสมบูรณ์ (**ไม่ใช่ `tar` ไฟล์ DB ขณะแอปรัน**), เก็บนอกเครื่องแบบเข้ารหัส 1 ชุด, ซ้อมกู้ทุกเดือน

## พื้นที่ GHCR

org แพ็กเกจ Free มีพื้นที่ Packages จำกัด (ใช้ร่วมกับ artifact ของ Actions) — ดูที่ org Settings → Billing
job `cleanup` ใน `image.yml` ลบให้อัตโนมัติหลังทุก merge: เก็บทุกเวอร์ชันที่ release แล้ว + `main` + `latest` + `sha-*` ล่าสุด 3 ตัว
เวอร์ชันที่ release แล้วไม่ถูกลบอัตโนมัติ — ลบเวอร์ชันเก่ามากที่ไม่ใช้แล้วเองที่หน้า Packages ของ repo

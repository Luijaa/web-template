# Backup และการกู้คืน

ใช้กับ production ทุกเครื่อง (dev ใช้แค่ "backup ก่อน deploy") — คนเป็นผู้ตั้งและดูแล agent ห้ามแตะเครื่อง production
แนวทาง: กฎ 3-2-1 และ ISO/IEC 27001:2022 control 8.13 (Information backup) — ดู `docs/standards.md`

## เป้าหมาย (RPO / RTO)

| | ค่าเริ่มต้น | ความหมาย |
|---|---|---|
| **RPO** | 24 ชั่วโมง | ข้อมูลหายได้มากสุดเท่านี้ → backup อย่างน้อยวันละครั้ง |
| **RTO** | 4 ชั่วโมง | ระบบกลับมาใช้ได้ภายในเท่านี้ นับจากเริ่มกู้ |

ระบบที่ต้องการค่าต่ำกว่านี้ (เช่น RPO 1 ชั่วโมง) ให้เขียน ADR และปรับรอบ backup ตาม — ค่าที่ใช้จริงเขียนไว้ใน `docs/architecture.md`

## กฎ 3-2-1

- **3** ชุด: ข้อมูลจริง + backup อีก 2 ชุด
- **2** ที่เก็บต่างชนิดกัน: เช่น disk ของเครื่อง + object storage
- **1** ชุดอยู่นอกเครื่อง/นอก site: object storage (S3, OCI Object Storage, R2) หรือเครื่องอื่น — **ไฟล์ backup ที่อยู่แค่บนเครื่องเดียวกับแอปไม่นับเป็น backup** (เครื่องเสียหรือโดน ransomware ก็หายพร้อมกัน)
- ชุดนอกเครื่อง: **เข้ารหัสก่อนส่ง** และ credential ที่ใช้ส่งเขียนได้อย่างเดียว ลบไม่ได้ (หรือเปิด object lock/versioning) ถ้าเครื่องโดนยึดจะลบ backup ไม่ได้
- เครื่องมือแนะนำ: [restic](https://restic.net/) (BSD-2-Clause) — เข้ารหัส, dedup, ส่งไป S3/SFTP/rclone ได้, มี `restic check` ตรวจความครบ; pin เวอร์ชัน image เช่น `restic/restic:<เวอร์ชัน>` ตาม `docs/dependencies.md`

## เก็บกี่ชุด

ค่าเริ่มต้น: รายวัน 7 ชุด, รายสัปดาห์ 4 ชุด, รายเดือน 12 ชุด (`restic forget --keep-daily 7 --keep-weekly 4 --keep-monthly 12 --prune`)
ข้อมูลส่วนบุคคลที่ผู้ใช้ขอลบ (PDPA) จะหายจาก backup เมื่อชุดเก่าหมดอายุ — เขียนระยะเวลานี้ไว้ในนโยบายความเป็นส่วนตัวของระบบ

## วิธี backup ให้ได้ข้อมูลที่สมบูรณ์

**ห้าม `tar`/`cp` ไฟล์ฐานข้อมูลขณะแอปรันอยู่** — ได้ไฟล์ที่เขียนค้างครึ่งทาง กู้แล้วเปิดไม่ได้

| ข้อมูล | วิธี | ตรวจหลัง backup |
|---|---|---|
| SQLite (WAL) | `sqlite3 <db> ".backup <ไฟล์ปลายทาง>"` หรือ `VACUUM INTO` ผ่าน container ชั่วคราวที่ mount volume **แบบเขียนได้** (WAL ต้องเขียน `-shm` แม้ตอนอ่าน — mount `:ro` จะ error `unable to open database file`) และรันด้วย uid เดียวกับแอป ไม่งั้นไฟล์ `-wal`/`-shm` จะเป็นของ root แล้วแอปเปิดไม่ได้ | `PRAGMA integrity_check;` ต้องได้ `ok` |
| PostgreSQL | `pg_dump -Fc` จาก container ของ DB (หรือ `pg_dumpall --globals-only` คู่กันถ้ามี role) | `pg_restore --list` อ่านได้ |
| ไฟล์อัปโหลด | `tar` ได้ (ไฟล์เขียนครั้งเดียวไม่แก้ทีหลัง) หรือให้ restic อ่าน volume ตรง ๆ | จำนวนไฟล์ตรงกับต้นทาง |
| `.env` / secret | **ไม่รวม**ใน backup ข้อมูล — เก็บใน password manager ของทีมแยกต่างหาก | — |

- สคริปต์ backup อยู่ใน `scripts/backup.sh` ของ repo: ทำ backup ที่สมบูรณ์ → ตรวจ → บีบอัด → ส่งนอกเครื่อง → ลบชุดเก่า; exit ≠ 0 เมื่อขั้นไหนพัง
- รันด้วย cron/systemd timer ของเครื่อง production เวลาไทยกลางคืน และ**แจ้งเตือนเมื่อพัง** (อย่างน้อย log + อีเมล/LINE ของผู้ดูแล) — backup ที่พังเงียบ ๆ เท่ากับไม่มี backup
- backup ทุกครั้งก่อน deploy เวอร์ชันใหม่ (migration ย้อนกลับไม่ได้)

## ทดสอบกู้คืน (restore drill)

**backup ที่ไม่เคยลองกู้ = ยังไม่รู้ว่ามี backup**

- ทำทุกเดือน และก่อน release MAJOR ทุกครั้ง
- กู้ลง**เครื่อง/compose project แยก** ไม่ทับ production: ดึงชุดล่าสุดจากที่เก็บนอกเครื่อง (ไม่ใช่จากเครื่อง production) → ถอดรหัส → ใส่ volume ใหม่ → `docker compose -p <ชื่อ>-restore -f compose.prod.yml up -d` ด้วย `APP_VERSION` เดียวกับ production
- ตรวจ: healthcheck ผ่าน, เวอร์ชัน migration ตรง, จำนวนแถวของตารางหลักใกล้เคียง production, login ได้, เปิดไฟล์อัปโหลดได้
- จับเวลาตั้งแต่เริ่มจนใช้งานได้ ต้องไม่เกิน RTO
- บันทึกผลใน `docs/restore-log.md` (วันที่, ชุด backup ที่ใช้, เวลาที่ใช้, ผล, ปัญหาที่เจอ) แล้วลบ project ที่กู้ทดสอบ (`down -v`)
- ถ้ากู้ไม่ได้หรือเกิน RTO: แก้ก่อน release ถัดไป

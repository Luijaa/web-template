---
name: pre-pr-check
description: Run the full pre-PR checklist (make check, secret scan, docs, diff review) before opening or updating a pull request. Use before creating a PR or when asked if work is ready.
---
# Pre-PR check

ทำทุกข้อ แล้วรายงานเป็นตาราง ผ่าน/ไม่ผ่าน พร้อมหลักฐาน (คำสั่งและผลย่อ)

1. `make check` ต้องผ่านทั้งหมด (docs-check, lint + SAST, test, build, license) — ยกเว้น 2 กรณี:
   - PR เอกสารอย่างเดียว (`docs(design): …`, ADR, docs): `make docs-check` ผ่านพอ
   - repo ที่ยังไม่เลือก stack (target พิมพ์ `not configured` — ADR-0001 ยังไม่ accepted): target นั้นรายงานเป็น **N/A (ยังไม่ตั้งค่า)** ไม่ใช่ผ่าน และไม่ใช่เหตุให้หยุด — ห้ามแก้ recipe ให้ `exit 0` เพื่อให้ผ่าน

   และ `make e2e` แบบเต็ม (ไม่ใส่ `SPEC`) ถ้าเปลี่ยนสิ่งที่ผู้ใช้เห็น (เพิ่ม/แก้ e2e ด้วย — skill `e2e-playwright`) และ `make dast` ถ้าแตะ middleware, header, cookie, หน้า error หรือ route ใหม่
2. `git diff origin/main...HEAD --stat` — ดูว่าแตะเฉพาะไฟล์ที่เกี่ยวกับงาน ไม่มีไฟล์หลุด (build output, .env, ไฟล์ส่วนตัว)
3. log ชั่วคราวที่ลืมลบ: `git diff origin/main...HEAD | grep -n '\[DBG-'` ต้องไม่เจอ (`fix-bug` ข้อ 3)
4. หา secret ใน diff: `git diff origin/main...HEAD | grep -nEi '(api[_-]?key|secret|token|password|BEGIN .*PRIVATE KEY)'` — ถ้าเจอให้หยุดและแจ้ง
5. ตัวแปร env ใหม่อยู่ใน `.env.example` ครบ
6. dependency ที่เพิ่ม/อัปเกรด (ดู diff ของ lockfile, go.mod, Dockerfile `FROM`): เวอร์ชันและ license ตรงตาม `docs/dependencies.md` และระบุใน PR description
7. migration ใหม่ (ถ้ามี) รันได้และย้อนกลับได้
8. เอกสาร: README/docs/ADR (`docs/adr/`) อัปเดตตามที่เปลี่ยน; คำใหม่ของโดเมนอยู่ใน CONTEXT.md และชื่อในโค้ดตรงกับ CONTEXT.md
9. รีวิวตาม skill `review` (Claude Code: subagent `reviewer`; agent อื่น: อ่าน `.agents/skills/review/SKILL.md` แล้วตรวจ diff ตัวเอง) และแก้ข้อ "ต้องแก้" ก่อน
10. commit message เป็น Conventional Commits และ branch ไม่ใช่ `main`
11. PR description มี `Closes #<issue>` (ไม่มี issue ให้เปิดก่อน) และหัวข้อ `## CHANGELOG` (หมวด + 1 บรรทัดภาษาไทยมุมผู้ใช้ หรือ `-`) — ไม่แก้ `CHANGELOG.md` เอง (`docs/release.md`)
12. แตะ UI: ไม่มีข้อความ hardcode, key ครบทุกภาษา, ไม่มีค่าสีตรง ๆ, ดูแล้วทั้ง `th`/`en` × light/dark (`docs/ui.md`)

ถ้าข้อใดไม่ผ่าน ห้ามเปิด PR ให้แก้ก่อนหรือรายงานว่าติดอะไร

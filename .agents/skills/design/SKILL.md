---
name: design
description: Design a new system or a large feature before any code — interview in rounds, write docs/design/<slug>.md from the template, ADRs and glossary, run make docs-check, and open a docs-only PR for approval. Use when asked to design something, or when /new-feature finds the feature is large.
argument-hint: "<system or feature to design>"
source: written for this template — docs/design-process.md
---
# Design: $ARGUMENTS

ทำตาม `docs/design-process.md` ทุกขั้น — ไฟล์นั้นคือกติกา skill นี้แค่ลำดับงาน ถ้าขัดกันให้ยึดไฟล์นั้น

1. **ต้อง design ไหม** — เทียบกับตารางหัวข้อ 1 ของ `docs/design-process.md`
   - ไม่ต้อง: บอกเหตุผล 1 บรรทัด แล้วกลับไปใช้ `new-feature`
   - ไม่แน่ใจ: ถามคนก่อน
2. **เริ่ม** (หัวข้อ 3.0): epic issue (label `design`), branch `docs/<id>-design-<slug>`, คัดลอก `docs/design/template.md` → `docs/design/<slug>.md` (`system.md` หรือ `<เลข epic>-<slug>.md`) ตั้ง `status: draft` และเพิ่มแถวใน `docs/design/README.md`
3. **อ่านก่อนถาม**: `CONTEXT.md`, `docs/adr/`, `docs/architecture.md`, design อื่นใน `docs/design/` — ข้อเท็จจริงที่หาเองได้ไปหาเอง ห้ามถาม
4. **สัมภาษณ์เป็นรอบ** (หัวข้อ 3.1) รูปแบบ `Qn — หัวข้อ: คำถาม` + `แนะนำ: …` ทุกข้อ, เหตุการณ์ขอบ 1–2 ข้อทุกรอบ — เดินกิ่ง A–H (หัวข้อ 3.2) ให้ครบ และหยุดรอคนที่จุดอนุมัติ 1, 2 (system), 3
5. **เขียนลงไฟล์หลังทุกรอบ**: หัวข้อในไฟล์ design, คำใหม่ใน `CONTEXT.md`, ADR `proposed` ใน `docs/adr/` (+ ดัชนี), รูป C4 ใน `docs/architecture.md` ถ้า container/ระบบภายนอกเปลี่ยน
6. **ตรวจ** (หัวข้อ 3.3): `make docs-check` ต้องผ่าน (repo ที่ Makefile ยังไม่มี target นี้: `python3 <path ของ web-template>/scripts/check-docs.py <repo>` — ทีม Hermes: `/home/opc/projects/web-template`) + เช็คลิสต์ด้วยตัวเอง แล้วตั้ง `status: proposed`
7. **PR เอกสารอย่างเดียว**: `docs(design): <slug>`, body มี `Refs #<epic>`, สรุปทางเลือกที่ยังเปิด และหัวข้อ `## CHANGELOG` เป็น `-` — ห้ามมีโค้ด ห้าม merge
8. **อนุมัติ** (หัวข้อ 3.4): เมื่อคนอนุมัติ commit `status: approved` + `approved-by` + ADR เป็น `accepted` ใน PR เดียวกัน (`make docs-check` ต้องผ่าน) แล้วให้คน merge
9. **หลัง merge** (หัวข้อ 3.5): เปิด issue ย่อยตามหัวข้อ 13 ทีละชิ้น แต่ละใบลิงก์ epic และไฟล์ design — งานโค้ดเริ่มด้วย `new-feature`

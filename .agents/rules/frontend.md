---
paths:
  - "web/**"
  - "**/templates/**"
  - "**/*.templ"
  - "**/*.html"
  - "**/*.css"
  - "**/locales/**"
---
# Frontend rules (UI)

รายละเอียดและเหตุผลอยู่ใน `docs/ui.md`

- ทำตาม framework/โครงสร้างใน `docs/adr/` — ห้ามเพิ่ม UI library ใหม่โดยไม่มี ADR
- component เล็ก ทำหน้าที่เดียว; logic ที่ทดสอบได้แยกออกจาก component
- เรียก API ผ่าน client module เดียว (เช่น `web/src/api/`) ห้าม hardcode URL — ใช้ค่าจาก env/config
- ทุกฟอร์ม: validate ฝั่ง client (UX) แต่ห้ามเชื่อแทน validation ฝั่ง API
- **หลายภาษา (i18n)**: รองรับ `th` (ค่าเริ่มต้น) และ `en`; ข้อความที่ผู้ใช้เห็นทุกข้อมาจากไฟล์แปล ห้าม hardcode ใน component/template; key ตั้งตามความหมาย; ใส่ตัวแปรด้วยชื่อ ห้ามต่อ string; key ต้องครบทุกภาษา (มี test); สถานะ/ประเภทเก็บเป็นรหัสแล้วแปลตอนแสดง ห้ามแสดงรหัสดิบ; `<html lang>` ตรงกับภาษาที่แสดง
- วันที่/ตัวเลข/เงิน format ด้วย API ที่อิง CLDR พร้อม locale และ `Asia/Bangkok` ตรง ๆ; ภาษาไทยระบุปฏิทินชัดเจน (`th-TH-u-ca-buddhist` หรือ `th-TH-u-ca-gregory` ตาม ADR) ห้ามปล่อยค่าเริ่มต้น
- ตัวอักษรไทย: font รองรับไทย (license OFL), `line-height` ≥ 1.5, ห้าม `word-break: break-all` กับข้อความไทย
- **theme**: รองรับ `system` (ค่าเริ่มต้น) / `light` / `dark`; สีทั้งหมดเป็น CSS custom property ห้ามใส่ค่าสีตรง ๆ ใน component; เก็บโหมดใน cookie `theme` และ server ใส่ `data-theme` บน `<html>` (ไม่กะพริบ, ไม่ต้อง inline script); มี `<meta name="color-scheme" content="light dark">`
- **accessibility ตาม WCAG 2.2 AA ทั้ง light และ dark**: label ทุก input, `<button>`/`<a>` จริง ไม่ใช่ div, contrast ข้อความ 4.5:1 และ UI 3:1, focus มองเห็น, ใช้คีย์บอร์ดได้ทั้งหมด, เป้ากดอย่างน้อย 24×24 px, เคารพ `prefers-reduced-motion`
- ห้ามเก็บ token/ข้อมูลอ่อนไหวใน localStorage
- ทุกหน้าที่เพิ่ม/แก้ ต้องมี test อย่างน้อย render + interaction หลัก; e2e ของหน้าหลักตรวจ axe (WCAG 2.2 AA) ทั้ง 2 theme

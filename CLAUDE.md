@AGENTS.md

## เฉพาะ Claude Code

- งานที่แตะหลายไฟล์หรือเปลี่ยนโครงสร้าง ให้เริ่มด้วย plan mode แล้วให้คนยืนยันก่อนแก้
- ออกแบบระบบใหม่/ฟีเจอร์ใหญ่ด้วย `/design <เรื่อง>` (`docs/design-process.md`) ก่อนเขียนโค้ด
- เริ่มฟีเจอร์ใหม่ด้วย `/new-feature <คำอธิบาย>`, แก้บั๊กด้วย `/fix-bug <issue>` และก่อนเปิด PR รัน `/pre-pr-check`
- หลังแก้โค้ดเสร็จ ใช้ subagent `reviewer` ตรวจ diff ก่อนบอกว่างานเสร็จ
- ไฟล์ที่แก้จะถูก format อัตโนมัติด้วย `.claude/hooks/format.sh` ไม่ต้องรัน formatter เอง
- การตั้งค่าส่วนตัว (ไม่ commit) ใส่ใน `CLAUDE.local.md` — ดูตัวอย่างที่ `CLAUDE.local.md.example`
- `/grill-with-docs` ใช้ทบทวนแผนได้ แต่ผลต้องลงไฟล์ตาม `docs/design-process.md` (design ใน `docs/design/`, glossary ใน `CONTEXT.md`, ADR ใน `docs/adr/`) เพื่อให้ตรงกับ agent อื่น

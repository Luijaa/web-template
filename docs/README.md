# เอกสาร

จัดตาม [Diátaxis](https://diataxis.fr/) — เอกสารแต่ละไฟล์ตอบความต้องการแบบเดียว ผู้อ่าน (คนและ agent) จึงรู้ว่าจะหาอะไรที่ไหน

| ประเภท | ผู้อ่านต้องการ | เขียนอย่างไร |
|---|---|---|
| **Tutorial** | เรียนรู้ครั้งแรก ทำตามแล้วสำเร็จ | ขั้นตอนเดียวทางเดียว ผลลัพธ์แน่นอน ไม่อธิบายทางเลือก |
| **How-to** | ทำงานที่รู้อยู่แล้วว่าต้องทำ | ขั้นตอนเป็นข้อ เริ่มจากเป้าหมาย จบเมื่องานเสร็จ ไม่สอนพื้นฐาน |
| **Reference** | ค้นข้อเท็จจริง/กฎ | ตาราง รายการ ครบและแม่น ไม่มีเรื่องเล่า |
| **Explanation** | เข้าใจว่าทำไม | เหตุผล บริบท ทางเลือกที่ไม่เลือก |

## ดัชนี

| ไฟล์ | ประเภท | เรื่อง |
|---|---|---|
| [`../README.md`](../README.md) | tutorial | clone, setup, รันครั้งแรก |
| [`design-process.md`](design-process.md) | how-to | ออกแบบระบบใหม่/ฟีเจอร์ใหญ่ก่อนเขียนโค้ด |
| [`deploy-prod.md`](deploy-prod.md) | how-to | เตรียมเครื่องและ deploy/rollback production |
| [`release.md`](release.md) | how-to | เตรียม CHANGELOG และปล่อยเวอร์ชัน, ดู SBOM |
| [`backup.md`](backup.md) | how-to | backup และซ้อมกู้คืน |
| [`stacks/`](stacks/README.md) | how-to | สูตรตั้ง Makefile/Dockerfile/compose/health/e2e ตาม stack (Go+Templ+HTMX, Next.js) |
| [`testing.md`](testing.md) | reference | ชั้นการทดสอบ, SAST/DAST, วิธีเขียน e2e |
| [`dependencies.md`](dependencies.md) | reference | นโยบายเวอร์ชันและ license |
| [`standards.md`](standards.md) | reference | มาตรฐานที่ใช้ และกฎอยู่ไฟล์ไหน |
| [`ui.md`](ui.md) | reference | หลายภาษา, theme, accessibility |
| [`ai-agents.md`](ai-agents.md) | reference | ความปลอดภัยของ AI agent และฟีเจอร์ AI ในแอป |
| [`restore-log.md`](restore-log.md) | reference | ผลการซ้อมกู้คืน |
| [`../CONTEXT.md`](../CONTEXT.md) | reference | คำศัพท์ของโดเมน |
| [`architecture.md`](architecture.md) | explanation | โครงสร้างระบบ (C4) และข้อมูลหลัก |
| `postmortems/` (ถ้ามี) | explanation | บันทึกเหตุการณ์บน production: ลำดับเวลา, ผลกระทบ, สาเหตุ, ป้องกันครั้งหน้า (skill `fix-bug`) |
| [`adr/`](adr/README.md) | explanation | การตัดสินใจสำคัญและเหตุผล |
| [`design/`](design/README.md) | explanation | design ที่อนุมัติแล้ว: journey, สิทธิ์, สถานะ, data model, wireframe, threat model |

## กติกา

- เอกสารใหม่เลือกประเภทเดียว และเพิ่มแถวในดัชนีนี้ใน PR เดียวกัน
- เนื้อหาคนละประเภทอยู่ไฟล์เดียวกันได้เฉพาะเมื่อแยกหัวข้อชัด (เช่น how-to ที่มีหัวข้อ "ทำไม" สั้น ๆ ท้ายไฟล์) — ถ้าส่วนนั้นยาวเกินครึ่งหน้า ให้แยกไฟล์
- how-to ห้ามอธิบายยาวกลางขั้นตอน ให้ลิงก์ไป explanation; reference ห้ามมีขั้นตอน ให้ลิงก์ไป how-to
- ข้อมูลอย่างเดียวกันเขียนที่เดียว ที่อื่นลิงก์มา (กฎอยู่ `.agents/rules/` หรือ reference, เหตุผลอยู่ ADR)
- เปลี่ยนโค้ดที่ทำให้เอกสารไม่ตรง ต้องแก้เอกสารใน PR เดียวกัน

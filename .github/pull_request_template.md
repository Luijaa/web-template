## ทำอะไร
<!-- 1–3 บรรทัด และลิงก์งาน/การ์ด -->

Closes #
Design: <!-- docs/design/<slug>.md (approved) หรือ "ไม่ต้อง — <เหตุผล>" (docs/design-process.md) -->

<!-- บั๊ก: เพิ่มหัวข้อ "## สาเหตุ" ตาม skill fix-bug (อาการ, สาเหตุ, ทำไมแก้ตรงนี้, ตรวจแล้ว, ทำไมหลุดมาได้) -->

## Acceptance criteria
- [ ] 

## ทดสอบยังไง
<!-- คำสั่งที่รัน + ผล, ขั้นตอนลองบน dev -->

## CHANGELOG
<!-- ผลต่อผู้ใช้/ผู้ดูแล ภาษาไทย 1 บรรทัดต่อเรื่อง: Added | Changed | Deprecated | Removed | Fixed | Security
     ไม่มีผล (test/CI/refactor/เอกสารภายใน) ใส่ - ; ห้ามแก้ CHANGELOG.md ใน PR นี้ (docs/release.md) -->
Fixed: 

## Checklist
- [ ] `make check` ผ่าน (รวม `make docs-check`)
- [ ] งานที่ต้อง design: ตรงกับ design ที่อนุมัติ หรือแก้ไฟล์ design ใน PR นี้แล้ว
- [ ] `make e2e` ผ่าน (ถ้าเปลี่ยนสิ่งที่ผู้ใช้เห็น ต้องมี/แก้ e2e)
- [ ] CI เขียวทุก job (check, e2e, dast, security, image)
- [ ] มี/แก้ test สำหรับสิ่งที่เปลี่ยน
- [ ] ไม่มี secret, env ใหม่อยู่ใน `.env.example`
- [ ] dependency ใหม่/อัปเกรด: ระบุ ชื่อ@เวอร์ชัน, license, เหตุผล — ตรงตาม `docs/dependencies.md` (N-1 / stable ≥ 14 วัน / license ที่ใช้ได้)
- [ ] แตะสิทธิ์/การเปลี่ยนสถานะ: ไล่ทุก route ที่เขียนข้อมูลนั้นแล้ว ตรวจสิทธิ์ฝั่ง server ก่อนเขียน DB และมี test ที่ได้ 403/422
- [ ] รับ id อ้างถึงข้อมูลอื่นจากผู้ใช้ (เช่น `asset_id`): server ตรวจว่าผู้ใช้มีสิทธิ์ใช้ข้อมูลนั้น (ไม่ใช่แค่มีอยู่) และมี test ที่ส่ง id ของคนอื่นแล้วได้ 403/422
- [ ] แตะ UI: ข้อความจากไฟล์แปลครบ `th`/`en`, สีจาก token ใช้ได้ทั้ง light/dark, WCAG 2.2 AA (`docs/ui.md`)
- [ ] แตะ IP ผู้ใช้/proxy: อ่าน `X-Forwarded-For` เฉพาะจาก `TRUSTED_PROXIES` และไล่จากขวา (`.agents/rules/api.md`)
- [ ] action ใหม่ที่แก้ข้อมูล/สิทธิ์ มี audit log และ test (`.agents/rules/api.md`)
- [ ] dependency/skill/MCP ใหม่: ตรวจแล้วว่ามีจริงใน registry และ repo ตรง (`docs/ai-agents.md`)
- [ ] แก้ไฟล์กฎกลาง (`AGENTS.md`, `.claude/**`, `.agents/**`, `.github/**`, `Makefile`, `scripts/**`): ระบุให้คนอ่าน diff ก่อน merge
- [ ] อัปเดต docs (ดัชนี `docs/README.md`, รูป C4 ถ้าโครงสร้างเปลี่ยน) / ADR ใน `docs/adr/` (ถ้ามีการตัดสินใจใหม่)
- [ ] ผ่าน reviewer แล้ว

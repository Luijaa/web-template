---
name: e2e-playwright
description: Write, run and fix Playwright e2e tests in e2e/tests — run one spec while iterating (make e2e SPEC=...), read error-context.md before changing anything, pick selectors, keep tests independent of shared seeded users, and wait for transitions/HTMX instead of sleeping. Use when adding or editing e2e tests or when make e2e or the CI e2e job fails.
source: เขียนเองจาก docs/testing.md และ https://playwright.dev/docs/best-practices (อ่านเมื่อ 2026-10-22)
---
# e2e (Playwright)

กติกาหลักอยู่ `docs/testing.md` หัวข้อ e2e — skill นี้คือวิธีทำงานกับมันให้เร็วและไม่ flaky

## 1. รัน

| คำสั่ง | ใช้เมื่อ | เวลา |
|---|---|---|
| `make e2e SPEC=tests/<ชื่อ>.spec.ts` | ระหว่างเขียน/แก้ — รันแค่ spec ที่แตะ (หลายไฟล์คั่นด้วยช่องว่าง, `:<บรรทัด>` = test เดียว) | build + ~1 นาที |
| `make e2e` | **ก่อนเปิด/อัปเดต PR ทุกครั้ง** — ครบทุก spec (CI รันแบบนี้) | build + 4–5 นาที |

- ผล: `e2e/.results/test-results/<test>/error-context.md` (error + page snapshot + โค้ดรอบบรรทัดที่ fail), report `e2e/.results/report/index.html`; ให้ `scripts/e2e.sh` พิมพ์ log ท้ายของ `web` เมื่อ fail
- repo ที่ `make e2e` ยังไม่รับ `SPEC` → เพิ่มตาม docs/testing.md หัวข้อ e2e ก่อน
- รายงานผลแนบจำนวน passed/failed/flaky ของ**รอบเต็ม**เท่านั้น

## 2. เมื่อ fail — อ่านก่อนแก้
1. เปิด `error-context.md` ของ test ที่ fail ก่อนแตะโค้ด
   - page snapshot เป็นข้อความ error ของ server (เช่น `SQL logic error`, 500) → บั๊กฝั่ง server ไม่ใช่ test: ดู web log ท้าย output แล้วแก้ที่ handler/repository
   - `toHaveAttribute`/`toHaveText` ได้ค่าอื่น → state ไม่ใช่ที่คิด (ข้อ 4) หรือหน้ายังไม่เปลี่ยน (ข้อ 5)
   - timeout ที่ `waiting for locator(...)` → element ไม่มีจริง: เทียบ selector กับ page snapshot
2. โฟลเดอร์ `...-retry1` แปลว่ารอบแรก fail รอบสองผ่าน = flaky — หาสาเหตุ ห้ามปล่อยไว้
3. test เดิมที่ไม่ได้แตะ fail หลังเปลี่ยนโค้ด → โค้ดใหม่ทำพัง (เช่น แก้ layout กลางแล้ว spec ภาษา/theme/เมนูพัง) ไม่ใช่ test ผิด — ห้ามแก้ assertion ของ test เดิมให้ผ่าน

## 3. เขียน test
- ไฟล์ `e2e/tests/<feature>.spec.ts` ต่อ 1 กลุ่มหน้าจอ; login ผ่าน helper ต่อ role ใน `e2e/tests/helpers.ts` (รหัสผ่านมาจาก env ที่ `scripts/e2e.sh` สุ่มให้ — ห้ามใส่ค่าเอง)
- selector: `getByRole(..., { name })`, ข้อความที่ผู้ใช้เห็น หรือ `id` ของ form/element (`#title`, `#user-name`) — ไม่ใช้ class CSS; ข้อความที่มีสองภาษาใช้ regex `/(บันทึก|Save)/`
- สิทธิ์ (RBAC): ทุก route ใหม่มี test ว่า role ที่ไม่มีสิทธิ์ได้ 403/404 — ใช้ `page.request.get/post` ตรวจ `status()` หลัง login เป็น role นั้น (session cookie ไปด้วย)
- เวลา: container ตั้ง `TZ: Asia/Bangkok` และ browser `timezoneId: Asia/Bangkok` — ตรวจเวลาที่แสดงเป็นเวลาไทย
- test ใน `test.describe.serial` แชร์ค่ากันได้ (เช่น URL ที่สร้างในข้อแรก) — ข้ามไฟล์ห้าม

## 4. ข้อมูลและ state — สาเหตุ flaky อันดับ 1
- ไฟล์ spec รันขนาน**หลาย worker** (`fullyParallel: false` แค่ใน 1 ไฟล์) และใช้ user seed ชุดเดียวกัน
- สร้างข้อมูลเองด้วยชื่อไม่ซ้ำ: `` `E2E ${Date.now()}` `` — ห้ามพึ่งข้อมูลที่ test อื่นสร้าง หรือนับจำนวนแถวทั้งตาราง (ค้นแถวของตัวเองแทน)
- **ห้ามเปลี่ยน preference ของ user seed (ภาษา, theme) ค้างไว้** — ค่าเก็บใน DB ต่อ user จึงไปโผล่ใน spec อื่นที่รันพร้อมกัน (`<html lang>` ไม่ใช่ที่คาด); ต้องเปลี่ยน → คืนค่าเดิมใน `finally`/`afterEach` หรือสร้าง user ใหม่ใน test
- ลบ/เก็บถาวรได้เฉพาะข้อมูลที่ test สร้างเอง

## 5. รอให้ถูก — ห้าม `waitForTimeout`
- รอผลที่ผู้ใช้เห็น: `await expect(locator).toHaveText(...)` / `toBeVisible()` / `expect(page).toHaveURL(...)` (auto-retry 10 วินาที)
- HTMX swap: รอ element ที่ถูก swap เข้ามา ไม่ใช่ `networkidle`
- axe / สีหลังสลับ theme: รอ CSS transition จบก่อน `AxeBuilder.analyze()` — helper `transitionsDone(page)` ใน `helpers.ts` (โค้ดใน docs/testing.md) ไม่งั้น axe เห็นสีครึ่งทาง

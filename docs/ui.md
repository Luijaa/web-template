# UI: หลายภาษา (i18n), theme และ accessibility

กฎสั้นอยู่ใน `.agents/rules/frontend.md` — ไฟล์นี้คือรายละเอียดและเหตุผล
ใช้กับทุก stack: SPA (`web/`), server-rendered template (Go templ, Jinja, Next.js RSC) และอีเมล/การแจ้งเตือน

## หลายภาษา (i18n)

### ภาษาที่รองรับ

- ค่าเริ่มต้น: **`th`** (ภาษาหลัก) และ **`en`** — รหัสภาษาตาม BCP 47 ใช้รหัสเดียวกันทุกที่ (`<html lang>`, cookie, ชื่อไฟล์แปล)
- เพิ่ม/ลดภาษา หรือไม่ทำหลายภาษา ต้องมี ADR — แต่ถึงจะมีภาษาเดียว **ก็ยังห้าม hardcode ข้อความ** (ข้อถัดไป) เพื่อให้เพิ่มภาษาทีหลังได้โดยไม่ต้องรื้อ

### ข้อความใน UI

- ข้อความที่ผู้ใช้เห็นทุกข้อ (ปุ่ม, label, หัวข้อ, error, อีเมล, ชื่อสถานะ) มาจากไฟล์แปล ไม่เขียนตรงใน component/template
- ไฟล์แปล 1 ไฟล์ต่อภาษา เช่น `locales/th.json`, `locales/en.json` (หรือรูปแบบของ library ที่เลือกใน ADR-0001)
- key ตั้งตามความหมาย ไม่ใช่ตามข้อความ: `ticket.status.in_progress`, `form.error.required` — ไม่ใช่ `"Save"`
- คำของโดเมนใช้ตาม `CONTEXT.md` ทั้งไทยและอังกฤษ (ช่อง `en:`) — คำเดียวกันต้องแปลเหมือนกันทุกหน้า
- ใส่ตัวแปรด้วยชื่อ ห้ามต่อ string: `"ticket.assigned": "มอบหมายให้ {name} แล้ว"` — ลำดับคำแต่ละภาษาไม่เหมือนกัน
- พหูพจน์และเพศใช้ ICU MessageFormat: `"{count, plural, one {# ticket} other {# tickets}}"` (ภาษาไทยไม่มีพหูพจน์ แต่อังกฤษมี)
- **ทุก key ต้องมีครบทุกภาษา** — มี test หรือ lint ที่ fail เมื่อขาด key หรือมี key ที่ไม่ได้ใช้ (รันใน `make lint` หรือ `make test`)
- ภาษาที่ขาด key ตอนรัน ให้ fallback ไป `th` และ log warning (ไม่แสดงชื่อ key ให้ผู้ใช้เห็น)

### ค่าที่เก็บใน DB

- สถานะ/ประเภท/บทบาทเก็บเป็น **รหัส** (`in_progress`) ไม่ใช่ข้อความที่แสดง — แปลเป็นข้อความตอนแสดงผลเท่านั้น (ห้ามแสดงรหัสดิบให้ผู้ใช้เห็น)
- ข้อมูลที่ผู้ใช้พิมพ์เอง (หัวข้อ, รายละเอียด, ชื่อ) ไม่แปล แสดงตามที่กรอก
- API ส่ง error เป็นรหัส + ตัวแปร (เช่น `code: "ticket.not_found"`) ให้ UI แปล; ถ้า server render HTML เอง ให้แปลฝั่ง server ด้วยภาษาของ request

### เลือกภาษา

ลำดับ: ภาษาที่ผู้ใช้เลือกเอง (เก็บใน profile ของผู้ใช้ + cookie `locale`) → header `Accept-Language` → `th`

- มีตัวเลือกภาษาในทุกหน้า (header หรือเมนูผู้ใช้) เป็น `<button>`/`<select>` จริง และชื่อภาษาเขียนเป็นภาษานั้นเอง ("ไทย", "English")
- URL: แอปภายในที่ต้อง login ใช้ cookie/profile **ไม่ต้องมี prefix ภาษาใน URL**; เว็บสาธารณะที่ต้องการ SEO ใช้ prefix (`/en/...`) + `<link rel="alternate" hreflang>` — เลือกใน ADR-0001
- ข้อความที่ส่งออกนอกเว็บ (อีเมล, LINE, PDF) ใช้ภาษาของ**ผู้รับ** ไม่ใช่ของคนที่กดส่ง
- cookie `locale`: `Path=/; SameSite=Lax; Max-Age=31536000` ไม่ต้อง `HttpOnly` ถ้า JS ต้องอ่าน (ไม่ใช่ข้อมูลลับ)

### รูปแบบวันที่ ตัวเลข เงิน

- format ด้วย API ที่อิง CLDR (`Intl.DateTimeFormat`, `Intl.NumberFormat`, `golang.org/x/text`, Babel) พร้อมระบุ locale และ `timeZone: "Asia/Bangkok"` ตรง ๆ ทุกครั้ง
- **กับดัก พ.ศ.:** `Intl` กับ locale `th` / `th-TH` ใช้ปฏิทินพุทธ (ปี 2569) เป็นค่าเริ่มต้น — ตัดสินใน ADR ว่าแสดงปีแบบไหน แล้วระบุให้ชัด: `th-TH-u-ca-buddhist` (พ.ศ.) หรือ `th-TH-u-ca-gregory` (ค.ศ.) ห้ามปล่อยตามค่าเริ่มต้น
- input วันที่ (`<input type="date">`) และค่าที่ส่งเข้า API ใช้ ISO 8601 ค.ศ. เสมอ ไม่ว่าจะแสดงแบบไหน
- เงินบาท: `Intl.NumberFormat(locale, { style: "currency", currency: "THB" })`

### ตัวอักษรไทย

- font ที่รองรับไทย license OFL (เช่น Noto Sans Thai, IBM Plex Sans Thai, Sarabun) พร้อม fallback `system-ui, sans-serif`; โหลดจาก repo หรือ CDN ที่อนุญาตใน CSP
- ภาษาไทยไม่เว้นวรรคระหว่างคำ: ห้ามใช้ `word-break: break-all` กับข้อความไทย; ใช้ `overflow-wrap: anywhere` กับ string ยาวที่ไม่มีช่องว่าง (URL, รหัส)
- `line-height` อย่างน้อย 1.5 (สระบน-ล่างและวรรณยุกต์ไม่ชนบรรทัดอื่น)
- เรียง/ค้นหาข้อความไทยด้วย collation ของภาษา (`Intl.Collator("th")`, DB collation ที่รองรับ) ไม่ใช่เรียงตาม byte

## Theme (light / dark)

- 3 โหมด: **`system`** (ค่าเริ่มต้น ตาม `prefers-color-scheme` ของเครื่อง), `light`, `dark`
- สีทั้งหมดเป็น CSS custom property (design token) บน `:root` เช่น `--color-bg`, `--color-text`, `--color-primary`, `--color-border`, `--color-danger` — **ห้ามใส่ค่าสีตรง ๆ ใน component/template**
- โครง CSS:

  ```css
  :root { color-scheme: light; --color-bg: #fff; --color-text: #1a1a1a; /* … */ }
  @media (prefers-color-scheme: dark) {
    :root:not([data-theme="light"]) { color-scheme: dark; --color-bg: #121212; --color-text: #e8e8e8; }
  }
  :root[data-theme="dark"] { color-scheme: dark; --color-bg: #121212; --color-text: #e8e8e8; }
  ```

  และ `<meta name="color-scheme" content="light dark">` ใน `<head>` — ฟอร์ม, scrollbar, date picker ของ browser จะเปลี่ยนตาม
- เก็บโหมดที่เลือกใน cookie `theme` (`light` | `dark`; ไม่มี cookie = `system`) และ server ใส่ `data-theme` บน `<html>` ตั้งแต่ HTML แรก — หน้าไม่กะพริบ และไม่ต้องมี inline script (ผ่าน CSP)
  - SPA ที่ไม่มี server render: ใช้ `localStorage` ได้ (ไม่ใช่ข้อมูลลับ) แต่ต้องตั้งค่าใน `<head>` ก่อน CSS โหลด และ CSP ต้องอนุญาตด้วย hash ไม่ใช่ `unsafe-inline`
- ปุ่มสลับ: `<button>` จริง มี `aria-label` และบอกสถานะปัจจุบัน (`aria-pressed` หรือ radio group 3 ตัวเลือก) ใช้คีย์บอร์ดได้ ข้อความบนปุ่มมาจากไฟล์แปล
- **contrast ตาม WCAG 2.2 AA ในทั้ง 2 โหมด**: ข้อความ 4.5:1, ข้อความใหญ่และขอบของ input/ปุ่ม/ไอคอนที่ใช้งานได้ 3:1, focus ring มองเห็นในทั้ง 2 โหมด
- รูป/โลโก้/กราฟ: มีแบบที่อ่านได้บนพื้นมืด (`<picture>` + `prefers-color-scheme` หรือ SVG ที่ใช้ `currentColor`); สีกราฟมาจาก token
- เคารพ `prefers-reduced-motion`: ปิด animation/transition ที่ไม่จำเป็น

## Accessibility (WCAG 2.2 AA)

- ทุก input มี `<label>`; error ของฟอร์มผูกกับ input ด้วย `aria-describedby` และไม่ใช้สีอย่างเดียวบอกว่าผิด
- ใช้ element ตามความหมาย: `<button>` สำหรับการกระทำ, `<a href>` สำหรับการไปหน้าอื่น, `<nav>`, `<main>`, หัวข้อ `<h1>`–`<h6>` เรียงลำดับ
- ใช้งานด้วยคีย์บอร์ดได้ทั้งหมด, focus มองเห็น, ลำดับ Tab ตามลำดับที่เห็น, มีลิงก์ "ข้ามไปเนื้อหาหลัก"
- ปุ่ม/ลิงก์ที่กดได้ ขนาดอย่างน้อย 24×24 px (WCAG 2.2 Target Size)
- รูปที่มีความหมายมี `alt`; ไอคอนตกแต่งใส่ `alt=""` หรือ `aria-hidden="true"`
- ข้อความที่อัปเดตเอง (HTMX swap, toast) ใช้ `aria-live="polite"`
- ขยายตัวอักษร 200% แล้วยังใช้งานได้ และหน้าจอกว้าง 320 px ไม่ต้องเลื่อนแนวนอน

## การทดสอบ

- unit/lint: ไฟล์แปลมี key ครบทุกภาษา และไม่มี key ที่ไม่ได้ใช้
- e2e อย่างน้อย:
  - สลับภาษา → ข้อความของ flow หลักเปลี่ยน และยังเป็นภาษาเดิมหลัง reload
  - สลับ theme → `<html data-theme>` เปลี่ยน และคงอยู่หลัง reload; Playwright `colorScheme: "dark"` + โหมด system → หน้าแสดงสีมืด
  - ตรวจ accessibility อัตโนมัติด้วย `@axe-core/playwright` (tag `wcag2a`, `wcag2aa`, `wcag21aa`, `wcag22aa`) ในหน้าหลักทั้ง light และ dark — ไม่มี violation
- ตรวจด้วยตาก่อน merge ฟีเจอร์ที่ผู้ใช้เห็น: ภาษาไทย + อังกฤษ × light + dark (ข้อความยาวของภาษาอังกฤษต้องไม่ล้นปุ่ม)

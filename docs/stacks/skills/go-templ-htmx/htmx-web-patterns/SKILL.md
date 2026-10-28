---
name: htmx-web-patterns
description: Best practices for HTMX (version 2.0.11), including partial DOM updates, polling notifications, modals, and progressive enhancement with hx-boost.
---
# HTMX Web Patterns

แนวปฏิบัติการใช้งาน HTMX (เวอร์ชัน 2.0.11) สำหรับสร้าง Interactive UI ร่วมกับ Go และ Templ

## 1. การอัปเดต DOM บางส่วน (Partial Updates)
- ใช้ `hx-get`, `hx-post`, `hx-put`, `hx-delete` สำหรับส่งคำขอ
- กำหนดเป้าหมายการเปลี่ยน DOM ด้วย `hx-target` และรูปแบบการสลับด้วย `hx-swap`:
  ```html
  <button hx-post="/items/123/assign"
          hx-target="#item-status-box"
          hx-swap="outerHTML">
      รับงาน
  </button>
  ```
- ตัวเลือก `hx-swap` ที่ใช้บ่อย:
  - `innerHTML`: แทนที่เนื้อหาข้างใน target
  - `outerHTML`: แทนที่ทั้งตัว element ของ target
  - `beforeend` / `afterbegin`: เพิ่ม element ต่อท้ายหรือก่อนหน้า (เช่น activity log)

## 2. In-app Polling Notification
- ใช้ `hx-trigger="every <interval>"` สำหรับดึงข้อมูลแจ้งเตือนอัตโนมัติ:
  ```html
  <div id="notifications-bell"
       hx-get="/notifications/unread-count"
       hx-trigger="every 10s"
       hx-swap="innerHTML">
      <span class="badge">0</span>
  </div>
  ```
- เมื่อผู้ใช้ไม่ได้โฟกัสหน้าจอ สามารถใช้ trigger filter หรือโหลดเฉพาะส่วนที่จำเป็นเพื่อประหยัดทรัพยากร

## 3. Modal และ Dialog Patterns
- โหลดเนื้อหา Modal แบบไดนามิกผ่าน HTMX:
  ```html
  <button hx-get="/items/123/reassign-modal"
          hx-target="#modal-container"
          hx-swap="innerHTML">
      ส่งต่องาน
  </button>
  <div id="modal-container"></div>
  ```
- ปิด Modal เมื่อทำงานสำเร็จ: Server ส่ง HTTP Response Header `HX-Trigger: closeModal` หรือคืน HTML ว่างเปล่าเพื่อเคลียร์ `#modal-container`

## 4. Progressive Enhancement ด้วย hx-boost
- ใช้ `hx-boost="true"` บน container หรือ `<main>` เพื่อแปลงลิงก์ `<a>` และ `<form>` ธรรมดาให้เป็น AJAX request อัตโนมัติ:
  ```html
  <body hx-boost="true">
      <!-- ลิงก์และฟอร์มทั้งหมดจะทำงานแบบ SPA โดยไม่ refresh ทั้งหน้า -->
  </body>
  ```
- ประวัติการเข้าชม (History / URL) จะอัปเดตผ่าน HTML5 History API อัตโนมัติ

## 5. การจัดการ Response Headers พิเศษของ HTMX
- `HX-Trigger`: สั่งให้ฝั่ง client trigger event บน DOM (เช่น refresh list หรือแสดง toast)
- `HX-Redirect`: สั่งให้ client redirect ไปยังหน้าใหม่
- `HX-Refresh`: สั่งให้ browser reload ทั้งหน้า (ใช้หลัง logout หรือกรณี reset session)

source: เขียนเองจาก https://htmx.org/docs/ (อ่านเมื่อ 2026-10-13) — ต้นแบบ itms-app (`luija-dev/itms-app` `eb2e290`)

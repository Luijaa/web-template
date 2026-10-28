---
name: templ-go-patterns
description: Guidelines and patterns for Templ components in Go (.templ), component syntax, rendering, and the code generation lifecycle. Use when writing UI templates or generating Templ code.
---
# Templ (Go) Patterns

แนวทางการเขียน Templ (`.templ`) ร่วมกับ Go สำหรับ rendering UI components

## 1. Syntax และการสร้าง Component
- นิยาม component ด้วยคีย์เวิร์ด `templ`:
  ```templ
  package templates

  templ Header(title string) {
      <header class="bg-white shadow">
          <h1 class="text-xl font-bold">{ title }</h1>
      </header>
  }
  ```
- การแทรกตัวแปรใช้ `{ variable }` — Templ ทำ auto-escaping ป้องกัน XSS
- Control Flow:
  - `if / else`:
    ```templ
    if isUrgent {
        <span class="text-red-600 font-bold">Urgent</span>
    } else {
        <span>Normal</span>
    }
    ```
  - `for`:
    ```templ
    for _, item := range items {
        <li>{ item.Name }</li>
    }
    ```
  - `switch / case`: รองรับ Go switch statement ปกติ

## 2. Layouts และ Composition
- การส่ง Component หรือ Children เข้าไปใน Layout:
  ```templ
  templ Layout(title, lang string) {
      <!DOCTYPE html>
      <html lang={ lang }>
          <head>
              <meta charset="UTF-8"/>
              <title>{ title }</title>
              <script src="/static/js/htmx.min.js"></script>
          </head>
          <body>
              { children... }
          </body>
      </html>
  }
  ```

## 3. การ Render ใน Go HTTP Handler
- Render component ลงใน `http.ResponseWriter` โดยใช้ method `Render`:
  ```go
  func HandleItem(w http.ResponseWriter, r *http.Request) {
      component := templates.ItemDetail(item)
      w.Header().Set("Content-Type", "text/html; charset=utf-8")
      if err := component.Render(r.Context(), w); err != nil {
          http.Error(w, err.Error(), http.StatusInternalServerError)
      }
  }
  ```

## 4. Lifecycle ของ Code Generation
- Templ ทำงานผ่าน Code Generator: แปลงไฟล์ `*.templ` เป็น `*_templ.go`
- **ห้ามแก้ไขไฟล์ `*_templ.go` โดยตรง** — แก้ไขเฉพาะไฟล์ `*.templ`
- ทุกครั้งที่สร้างหรือแก้ไขไฟล์ `.templ` ต้องรัน:
  ```bash
  templ generate
  ```
- ก่อน commit / เปิด PR ต้องรัน `templ generate` แล้วตรวจ:
  ```bash
  git diff --exit-code
  ```
  หากมี diff แสดงว่าลืม generate หรือ generated code ไม่ตรงกับ source `.templ`

source: เขียนเองจาก https://templ.guide (อ่านเมื่อ 2026-10-13) — ต้นแบบ itms-app (`luija-dev/itms-app` `eb2e290`)

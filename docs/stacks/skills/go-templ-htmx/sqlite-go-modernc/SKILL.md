---
name: sqlite-go-modernc
description: SQLite configuration and management using modernc.org/sqlite pure Go driver, WAL mode, busy timeout, and schema migrations with goose.
---
# SQLite with modernc.org/sqlite & Goose

แนวทางการตั้งค่าและการใช้งาน SQLite ร่วมกับ Go driver `modernc.org/sqlite` และเครื่องมือ migration `goose`

## 1. Pure Go Driver (modernc.org/sqlite)
- ใช้ driver `modernc.org/sqlite` เพื่อให้คอมไพล์แบบ Pure Go (`CGO_ENABLED=0`)
- รองรับการทำ Cross-compilation ทั้ง `linux/amd64` และ `linux/arm64` โดยไม่ต้องใช้ GCC toolchain
- Register driver ผ่าน database/sql:
  ```go
  import (
      "database/sql"
      _ "modernc.org/sqlite"
  )
  ```

## 2. การเปิดใช้งาน WAL Mode และ Connection Options
- เพื่อประสิทธิภาพการทำงานแบบ Concurrency และป้องกันข้อผิดพลาด database locked:
  - เปิดโหมด **WAL (Write-Ahead Logging)**
  - กำหนด `busy_timeout` เป็น 5000ms (5 วินาที)
  - เปิดใช้งาน `foreign_keys = ON`
- ตั้งค่าผ่าน DSN (Data Source Name):
  ```go
  dsn := "file:/app/data/app.db?_pragma=journal_mode(WAL)&_pragma=busy_timeout(5000)&_pragma=foreign_keys(ON)&_pragma=synchronous(NORMAL)"
  db, err := sql.Open("sqlite", dsn)
  ```
- หรือรัน PRAGMA ทันทีหลังเปิด connection:
  ```go
  if _, err := db.Exec(`
      PRAGMA journal_mode = WAL;
      PRAGMA busy_timeout = 5000;
      PRAGMA foreign_keys = ON;
  `); err != nil {
      log.Fatalf("failed to set pragma: %v", err)
  }
  ```

## 3. Connection Pooling สำหรับ SQLite
- SQLite WAL mode รองรับ Concurrent Reads ได้หลาย connection แต่ Write รองรับครั้งละ 1 transaction
- กำหนด Connection Pool ให้เหมาะสม:
  ```go
  db.SetMaxOpenConns(1) // ป้องกัน write lock contention
  db.SetMaxIdleConns(1)
  ```

## 4. Schema Migrations ด้วย Goose
- จัดเก็บไฟล์ migration ไว้ในไดเรกทอรี `migrations/` ในรูปแบบ SQL:
  ```sql
  -- +goose Up
  CREATE TABLE users (
      id TEXT PRIMARY KEY,
      email TEXT UNIQUE NOT NULL,
      password_hash TEXT NOT NULL,
      name TEXT NOT NULL,
      role TEXT NOT NULL,
      created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
  );

  -- +goose Down
  DROP TABLE users;
  ```
- embed migration ใน binary แล้วรันตอน start (`.agents/rules/api.md`):
  ```go
  import (
      "embed"

      "github.com/pressly/goose/v3"
  )

  //go:embed migrations/*.sql
  var migrations embed.FS

  goose.SetBaseFS(migrations)
  if err := goose.SetDialect("sqlite3"); err != nil {
      log.Fatal(err)
  }
  if err := goose.Up(db, "migrations"); err != nil {
      log.Fatal(err)
  }
  ```
- migration ที่ merge แล้วห้ามแก้ — เปลี่ยน schema ด้วยไฟล์ใหม่เสมอ
- ทุกตารางมาจาก migration ตั้งแต่ตารางแรก (ห้าม `CREATE TABLE` ในโค้ดตอนเริ่มแอป) และส่วน Up ห้าม `IF NOT EXISTS`/`IF EXISTS` — schema ไม่ตรงต้อง error ทันที ไม่ข้ามเงียบแล้วไปล้มที่คำสั่งถัดไป
- test ใช้ `goose.Up` ชุดเดียวกับของจริงบน `:memory:` — ห้ามสร้างตารางใน test แยก

source: เขียนเองจาก https://pkg.go.dev/modernc.org/sqlite, https://www.sqlite.org/wal.html, และ https://github.com/pressly/goose (อ่านเมื่อ 2026-10-13) — ต้นแบบ itms-app (`luija-dev/itms-app` `eb2e290`)

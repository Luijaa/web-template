---
name: go-testing-patterns
description: Testing patterns in Go, including table-driven unit tests, httptest for HTTP handlers/routers, assertions, and test database setups.
---
# Go Testing Patterns

แนวทางการเขียน Unit Tests, API/Handler Tests และ Integration Tests ในภาษา Go

## 1. Table-Driven Tests
- ใช้โครงสร้าง Slice of Struct เพื่อทดสอบหลาย test cases ภายใต้ฟังก์ชันเดียว:
  ```go
  func TestValidateTitle(t *testing.T) {
      tests := []struct {
          name    string
          title   string
          wantErr bool
      }{
          {name: "valid title", title: "Printer broken", wantErr: false},
          {name: "empty title", title: "", wantErr: true},
      }

      for _, tt := range tests {
          t.Run(tt.name, func(t *testing.T) {
              err := ValidateTitle(tt.title)
              if (err != nil) != tt.wantErr {
                  t.Errorf("ValidateTitle() error = %v, wantErr %v", err, tt.wantErr)
              }
          })
      }
  }
  ```

## 2. HTTP Handler Testing ด้วย `net/http/httptest`
- ใช้ `httptest.NewRecorder` และ `httptest.NewRequest` ทดสอบ handler และ Chi router:
  ```go
  func TestHandleGetItem(t *testing.T) {
      r := chi.NewRouter()
      r.Get("/items/{id}", HandleGetItem)

      req := httptest.NewRequest("GET", "/items/123", nil)
      rec := httptest.NewRecorder()

      r.ServeHTTP(rec, req)

      if rec.Code != http.StatusOK {
          t.Errorf("expected status 200, got %d", rec.Code)
      }
  }
  ```

## 3. Test Helpers และ Cleanup
- ใช้ `t.Helper()` ในฟังก์ชันช่วยเหลือเพื่อให้ log แจ้งเลขบรรทัดของผู้เรียกจริง
- ใช้ `t.Cleanup(func() { ... })` สำหรับปิด database หรือลบไฟล์ทดสอบชั่วคราว:
  ```go
  func setupTestDB(t *testing.T) *sql.DB {
      t.Helper()
      db, err := sql.Open("sqlite", ":memory:")
      if err != nil {
          t.Fatalf("failed to open test db: %v", err)
      }
      t.Cleanup(func() { db.Close() })
      return db
  }
  ```

## 4. การทดสอบเรื่องเวลา (Timezone Testing)
- เก็บเวลาเป็น UTC ใน DB และแสดงตาม timezone ของโปรเจกต์ (`docs/ui.md`) — ฟังก์ชันที่แสดงเวลาต้องมี test ยืนยันการแปลง (เช่น `Asia/Bangkok` UTC+7)
- ทดสอบกรณีเวลาข้ามเที่ยงคืน UTC (เช่น เก็บ 17:30Z ในฐานข้อมูล ต้องแสดงผลเป็น 00:30 ของวันถัดไปในเวลาไทย)

source: เขียนเองจาก https://go.dev/doc/tutorial/add-a-test, https://pkg.go.dev/net/http/httptest, และ https://go.dev/wiki/TableDrivenTests (อ่านเมื่อ 2026-10-13) — ต้นแบบ itms-app (`luija-dev/itms-app` `eb2e290`)

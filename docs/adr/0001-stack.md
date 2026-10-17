---
status: proposed
date: YYYY-MM-DD
decision-makers: TODO
---

# ADR-0001: Stack (frontend, backend, database)

## บริบทและปัญหา

เริ่มโปรเจกต์ใหม่จาก web-template ยังไม่ได้เลือก frontend/backend/database

## ปัจจัยในการตัดสินใจ

- แกนหลักเป็นสาย N-1 และ license ตาม `docs/dependencies.md`
- image ต้อง build ได้ทั้ง amd64 และ arm64
- รองรับหลายภาษาและ light/dark ตาม `docs/ui.md` (ต้องมี library i18n ที่ใช้ ICU MessageFormat หรือเทียบเท่า)

## ทางเลือกที่พิจารณา

- TODO

## ผลการตัดสินใจ

TODO

### ผลที่ตามมา

- เติม `make setup/lint/test/e2e/license`, Dockerfile, `docs/architecture.md`
- ตัดสินเรื่องหลายภาษาตาม `docs/ui.md`: ภาษาที่รองรับ, URL มี prefix ภาษาหรือไม่, ปีแสดงเป็น พ.ศ. หรือ ค.ศ.

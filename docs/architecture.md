# Architecture — {{PROJECT_NAME}}

> ประเภทเอกสาร: **explanation** (`docs/README.md`) — เติมหลังเลือก stack ใน `docs/adr/0001-stack.md` แล้ว อัปเดตใน PR เดียวกับที่โครงสร้างเปลี่ยน
> รูปตาม [C4 model](https://c4model.com/): ระดับ 1 (Context) และ 2 (Container) ต้องมีเสมอ, ระดับ 3 (Component) เฉพาะ container ที่ซับซ้อน, ไม่ทำระดับ 4 (Code)

## ระดับ 1: System Context

ใครใช้ระบบ และระบบคุยกับระบบภายนอกอะไรบ้าง — คนที่ไม่ใช่นักพัฒนาอ่านรูปนี้แล้วต้องเข้าใจ

```mermaid
flowchart TB
  user["👤 ผู้ใช้<br/><i>[Person]</i><br/>TODO: บทบาทตาม CONTEXT.md"]
  admin["👤 ผู้ดูแลระบบ<br/><i>[Person]</i>"]
  sys["{{PROJECT_NAME}}<br/><i>[Software System]</i><br/>{{ONE_LINE_DESCRIPTION}}"]
  mail["ระบบอีเมล<br/><i>[External System]</i><br/>TODO: ถ้ามี"]
  user -- "ใช้งานผ่านเว็บ [HTTPS]" --> sys
  admin -- "จัดการผู้ใช้/ตั้งค่า [HTTPS]" --> sys
  sys -- "ส่งแจ้งเตือน [SMTP]" --> mail
  classDef person fill:#08427b,color:#fff,stroke:#052e56
  classDef system fill:#1168bd,color:#fff,stroke:#0b4884
  classDef external fill:#999,color:#fff,stroke:#6b6b6b
  class user,admin person
  class sys system
  class mail external
```

## ระดับ 2: Container

แต่ละสิ่งที่ deploy แยกได้ (service ใน compose, DB, volume) และคุยกันด้วยอะไร

```mermaid
flowchart TB
  user["👤 ผู้ใช้<br/><i>[Person]</i>"]
  subgraph sys["{{PROJECT_NAME}} [Software System]"]
    proxy["Reverse proxy<br/><i>[Container: TODO]</i><br/>TLS, HSTS"]
    web["web<br/><i>[Container: TODO]</i><br/>UI, th/en, light/dark"]
    api["api<br/><i>[Container: TODO]</i><br/>business logic, authz, audit log"]
    db[("database<br/><i>[Container: TODO]</i><br/>ข้อมูลหลัก + audit log")]
  end
  user -- "HTTPS" --> proxy
  proxy -- "HTTP, X-Forwarded-For" --> web
  web -- "JSON/HTTP" --> api
  api -- "SQL" --> db
  classDef person fill:#08427b,color:#fff,stroke:#052e56
  classDef container fill:#438dd5,color:#fff,stroke:#2e6295
  class user person
  class proxy,web,api,db container
```

| container | เทคโนโลยี | หน้าที่ | อยู่ที่ | health |
|---|---|---|---|---|
| web | TODO | UI | `web/` | `/healthz`, `/readyz` |
| api | TODO | business logic, auth, audit log | `api/` | `/healthz`, `/readyz` |
| db | TODO | เก็บข้อมูล | container / managed | — |

<!-- ระดับ 3 (Component): เพิ่มเมื่อ container ไหนมี module ที่ต้องอธิบายการแบ่งหน้าที่ เช่น
## ระดับ 3: Component — api
```mermaid
flowchart LR
  h["HTTP handlers"] --> s["services (กฎสิทธิ์/สถานะ)"] --> r["repository (SQL)"]
  s --> a["audit"]
```
-->

## ข้อมูลหลัก (data model)

TODO: ER diagram (`erDiagram` ของ mermaid) ของ entity หลัก ชื่อตาม `CONTEXT.md`

## ข้อมูลส่วนบุคคล (PDPA)

| ข้อมูล | เก็บที่ | ใช้ทำอะไร | เก็บนานเท่าไร |
|---|---|---|---|
| TODO | | | |

## Auth และ session

TODO: วิธี login, บทบาทผู้ใช้, ค่า session timeout ที่ใช้จริง (`.agents/rules/api.md`)

## Audit log

TODO: ตารางที่เก็บ, เหตุการณ์ที่บันทึก, ระยะเก็บ, ใครดูได้ (`.agents/rules/api.md`)

## Backup

RPO / RTO ที่ใช้จริง และที่เก็บนอกเครื่อง (`docs/backup.md`)

## Environments

| env | URL | deploy โดย |
|---|---|---|
| local | http://localhost | `make up` |
| dev | {{DEV_URL}} | agent/CI จาก branch |
| prod | TODO | คนเท่านั้น |

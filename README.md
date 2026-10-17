# {{PROJECT_NAME}}

{{ONE_LINE_DESCRIPTION}}

## เริ่มต้น

```bash
git clone <repo-url> && cd {{PROJECT_NAME}}
scripts/setup-ai.sh     # เตรียม symlink, CLAUDE.local.md, .env, ตรวจเครื่องมือ
make help
```

## ทำงานกับ AI agent

| ไฟล์ | ใครอ่าน | ไว้ทำอะไร |
|---|---|---|
| `AGENTS.md` | ทุก agent (Claude Code, Hermes, Codex…) + คน | คำสั่งหลัก: โครงสร้าง, คำสั่ง make, กติกา git, Definition of Done |
| `CLAUDE.md` | Claude Code | import `AGENTS.md` + ส่วนเฉพาะ Claude |
| `CLAUDE.local.md` | Claude Code (ส่วนตัว, ไม่ commit) | ค่าเฉพาะเครื่องคุณ |
| `.claude/settings.json` | Claude Code | permission allow/ask/deny + hook format อัตโนมัติ |
| `.agents/rules/*.md` (= `.agents/rules/` symlink) | Claude Code โหลดเองตาม `paths:`; agent อื่นเปิดอ่านตาม `AGENTS.md` | กฎของ `web/`, `api/`, container/CI |
| `.agents/skills/` (= `.claude/skills/` symlink) | Claude Code + Hermes (project skills, ต้อง `hermes skills trust` ครั้งแรก) + agent อื่นที่อ่าน Agent Skills | `/design`, `/new-feature`, `/fix-bug`, `/pre-pr-check`, `/review` |
| `.claude/agents/reviewer.md` | Claude Code | subagent ตรวจ diff ก่อน PR — ใช้เกณฑ์จาก skill `review` (`.agents/skills/review/SKILL.md`) |
| `.mcp.json` | Claude Code | MCP server ของโปรเจกต์ (ว่างไว้ เพิ่มเมื่อจำเป็น และ pin เวอร์ชัน) |
| `CONTEXT.md` | ทุกคน + ทุก agent | glossary: คำของโดเมน, ชื่อที่ใช้ในโค้ด, คำที่ห้ามใช้ (ใช้กับ `/grill-with-docs` ของ Claude Code ได้) |
| `docs/dependencies.md` | ทุกคน + ทุก agent | นโยบายเวอร์ชัน (แกนหลัก N-1, library stable ≥ 14 วัน) และ license ที่ใช้ได้/ห้าม + `make license` |
| `docs/design-process.md` + `docs/design/` | ทุกคน + ทุก agent | ขั้นตอนออกแบบก่อนเขียนโค้ด (skill `design`) และ design ที่อนุมัติแล้ว |
| `docs/stacks/` | คนตั้งโปรเจกต์ + agent scaffold | สูตร Makefile/Dockerfile/compose ตาม stack จากโปรเจกต์จริง |
| `docs/README.md` | ทุกคน + ทุก agent | ดัชนีเอกสาร (Diátaxis) — เริ่มหาเอกสารจากที่นี่ |
| `docs/ai-agents.md` | ทุก agent + คน | ความปลอดภัยของ AI agent (prompt injection, secret, package ปลอม) |
| `docs/testing.md` | ทุกคน | ชั้นการทดสอบ (unit, SAST, e2e, DAST, security) และวิธีเขียน e2e |
| `docs/adr/` | ทุกคน | การตัดสินใจสำคัญ (stack, DB, auth) แบบ MADR 1 เรื่อง/ไฟล์ — บันทึกเฉพาะที่ย้อนกลับยาก + ต้องอธิบาย + มีทางเลือกจริง |
| `docs/standards.md` | ทุกคน | มาตรฐานสากลที่ใช้ และกฎแต่ละข้ออยู่ไฟล์ไหน |
| `docs/ui.md` | ทุกคน + ทุก agent | หลายภาษา (i18n), theme light/dark, accessibility |
| `docs/release.md` + `CHANGELOG.md` | ทุกคน | SemVer, วิธีเขียน CHANGELOG, ขั้นตอนปล่อยเวอร์ชัน, SBOM/provenance |
| `docs/backup.md` | ผู้ดูแล production | RPO/RTO, กฎ 3-2-1, วิธี backup ฐานข้อมูลให้สมบูรณ์, ซ้อมกู้คืน |

## Deploy

- **dev:** merge เข้า `main` → CI build image `ghcr.io/{{GITHUB_ORG}}/{{PROJECT_NAME}}:main` → dev server ดึงไปรัน
- **production:** เตรียม CHANGELOG ตาม [`docs/release.md`](docs/release.md) → สร้าง GitHub Release `vX.Y.Z` → image `:X.Y.Z` → รัน `compose.prod.yml` บนเครื่อง production (x86 หรือ ARM) — ดู [`docs/deploy-prod.md`](docs/deploy-prod.md)

<!-- template-only:start -->
## สร้างโปรเจกต์ใหม่จาก template นี้

1. GitHub → **Use this template** → Create a new repository
2. clone แล้วรัน `scripts/init-project.sh <ชื่อโปรเจกต์> "<คำอธิบาย>" <dev-url> "<ผู้ใช้>"` — เติมค่า, ลบหัวข้อนี้ออกจาก README และลบสคริปต์ตัวเอง (ใช้ครั้งเดียว)
3. `scripts/setup-ai.sh`
4. `git add -A && git commit -m "chore: init from web-template"` แล้วเปิด PR
5. ตัดสินใจ stack ใน `docs/adr/0001-stack.md` (รวมเรื่องหลายภาษาตาม `docs/ui.md`) แล้วเติม Makefile / Dockerfile
6. ตั้ง branch protection ของ `main` (ต้องใช้ GitHub Pro/Team สำหรับ private repo): ต้องผ่าน PR + CI, ห้าม force push
<!-- template-only:end -->

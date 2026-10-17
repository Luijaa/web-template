# มาตรฐานที่ใช้

มาตรฐานสากลที่ทุกโปรเจกต์จาก template นี้ทำตาม — คอลัมน์ "กฎอยู่ที่" คือที่เขียนวิธีใช้กับ repo นี้ (ถ้าขัดกัน ให้ทำตามไฟล์กฎ)
จะไม่ใช้ข้อไหนหรือเปลี่ยนเวอร์ชัน ให้เขียน ADR (`docs/adr/`)

## การทำงานร่วมกัน

| มาตรฐาน | ใช้กับ | กฎอยู่ที่ |
|---|---|---|
| [Conventional Commits 1.0.0](https://www.conventionalcommits.org/en/v1.0.0/) | commit message, ชื่อ PR | `AGENTS.md` |
| [Semantic Versioning 2.0.0](https://semver.org/spec/v2.0.0.html) | เลขเวอร์ชัน release `vX.Y.Z` | `docs/release.md` |
| [Keep a Changelog 1.1.0](https://keepachangelog.com/en/1.1.0/) | `CHANGELOG.md` | `docs/release.md` |
| [MADR 4.0](https://adr.github.io/madr/) | บันทึกการตัดสินใจ | `docs/adr/README.md` |
| [C4 model](https://c4model.com/) | รูปสถาปัตยกรรมระดับ Context + Container (mermaid) | `docs/architecture.md` |
| [Diátaxis](https://diataxis.fr/) | แบ่งเอกสารเป็น tutorial / how-to / reference / explanation | `docs/README.md` |
| [AGENTS.md](https://agents.md/), [Agent Skills](https://agentskills.io/) | คำสั่งและ skill ของ AI agent ทุกตัว | `AGENTS.md`, `.agents/skills/` |
| [EditorConfig](https://editorconfig.org/) | encoding UTF-8, LF, indent | `.editorconfig` |
| [SPDX License List](https://spdx.org/licenses/) | ชื่อ license ของ dependency | `docs/dependencies.md` |

## เว็บและ API

| มาตรฐาน | ใช้กับ | กฎอยู่ที่ |
|---|---|---|
| [WCAG 2.2](https://www.w3.org/TR/WCAG22/) ระดับ **AA** | accessibility ทุกหน้า ทั้ง light และ dark | `.agents/rules/frontend.md`, `docs/ui.md` |
| [BCP 47](https://www.rfc-editor.org/info/bcp47) | รหัสภาษา (`th`, `en`) ใน `lang`, cookie, ไฟล์แปล | `docs/ui.md` |
| [Unicode CLDR](https://cldr.unicode.org/) + [ICU MessageFormat](https://unicode-org.github.io/icu/userguide/format_parse/messages/) | รูปแบบวันที่/ตัวเลข/พหูพจน์ตามภาษา | `docs/ui.md` |
| [ISO 8601](https://www.iso.org/iso-8601-date-and-time-format.html) / [RFC 3339](https://www.rfc-editor.org/rfc/rfc3339) + [IANA tz](https://www.iana.org/time-zones) | เวลาใน API (มี timezone), `Asia/Bangkok` | `AGENTS.md`, `.agents/rules/api.md` |
| [RFC 9110](https://www.rfc-editor.org/rfc/rfc9110) | HTTP method/status code ให้ตรงความหมาย; `HEAD` ใช้ได้ทุกที่ที่มี `GET` | `.agents/rules/api.md` |
| [Kubernetes probes](https://kubernetes.io/docs/concepts/configuration/liveness-readiness-startup-probes/) | `/healthz` (liveness) + `/readyz` (readiness) | `.agents/rules/api.md`, `.agents/rules/container.md` |
| [RFC 9457](https://www.rfc-editor.org/rfc/rfc9457) Problem Details | รูปแบบ error ของ JSON API (`application/problem+json`) | `.agents/rules/api.md` |
| [OpenAPI 3.1](https://spec.openapis.org/oas/v3.1.0) | สเปกของ JSON API ที่ระบบอื่นเรียก | `.agents/rules/api.md` |
| [RFC 7239](https://www.rfc-editor.org/rfc/rfc7239) / `X-Forwarded-For` | หา IP ผู้ใช้หลัง reverse proxy | `.agents/rules/api.md`, `docs/deploy-prod.md` |
| [RFC 6265](https://www.rfc-editor.org/rfc/rfc6265) | cookie: `Secure`, `HttpOnly`, `SameSite` | `.agents/rules/api.md` |

## ความปลอดภัย

| มาตรฐาน | ใช้กับ | กฎอยู่ที่ |
|---|---|---|
| [OWASP Top 10 for LLM Applications 2025](https://genai.owasp.org/llm-top-10/) + OWASP Agentic AI | AI agent ที่แก้ repo และฟีเจอร์ AI ในแอป | `AGENTS.md`, `docs/ai-agents.md` |
| OWASP ASVS V16 (Security Logging) | audit log ใน DB | `.agents/rules/api.md` |
| OWASP ASVS V7 + NIST SP 800-63B AAL2 | session: idle 60 นาที, absolute 24 ชั่วโมง, เพิกถอนทันที | `.agents/rules/api.md` |
| [STRIDE](https://learn.microsoft.com/en-us/azure/security/develop/threat-modeling-tool-threats) / [OWASP Threat Modeling](https://owasp.org/www-community/Threat_Modeling) | threat model ของทุก design | `docs/design-process.md`, `docs/design/template.md` |
| [Trojan Source (CVE-2021-42574)](https://trojansource.codes/) | ตัวอักษรซ่อนในไฟล์ | CI job `security` |
| [OWASP ASVS 5.0](https://owasp.org/www-project-application-security-verification-standard/) ระดับ **L2** | เช็คลิสต์ความปลอดภัยของแอป (auth, session, access control, input) | `.agents/rules/api.md` (ตอนเขียนโค้ด), `.agents/skills/review/SKILL.md` หมวด E (ตอนรีวิว) |
| [OWASP Top 10](https://owasp.org/www-project-top-ten/) | ช่องโหว่ที่ reviewer ต้องไล่ทุก PR | `.agents/skills/review/SKILL.md` หมวด B–E (reviewer ทุกตัวใช้ไฟล์นี้ — `.claude/agents/reviewer.md` แค่ชี้มาที่นี่) |
| [NIST SP 800-63B](https://pages.nist.gov/800-63-4/sp800-63b.html) | นโยบายรหัสผ่าน: ความยาวขั้นต่ำ (rev 4: 15 ตัวเมื่อใช้รหัสผ่านอย่างเดียว, 8 ตัวเมื่อมี MFA), รับได้อย่างน้อย 64 ตัวและทุกอักขระ Unicode, ไม่บังคับผสมอักขระ, ไม่บังคับเปลี่ยนตามรอบ, เทียบกับรายการรหัสที่รั่ว, จำกัดการลองผิด | `.agents/rules/api.md` |
| [CSP Level 3](https://www.w3.org/TR/CSP3/), [HSTS (RFC 6797)](https://www.rfc-editor.org/rfc/rfc6797) | security header | `.agents/rules/api.md` |
| [SPDX 2.3](https://spdx.github.io/spdx-spec/v2.3/) SBOM + [SLSA v1.0](https://slsa.dev/spec/v1.0/) provenance (Build L1) | attestation ติดทุก image ที่ CI push | `.github/workflows/image.yml`, `docs/release.md` |
| SAST: gosec / eslint-plugin-security / ruff `S` (bandit) | ตรวจรูปแบบโค้ดเสี่ยงใน `make lint` | `docs/testing.md` |
| [OWASP ZAP](https://www.zaproxy.org/docs/docker/baseline-scan/) baseline (DAST) | สแกน production image ที่รันอยู่: header, cookie, error รั่ว | `.zap/rules.tsv`, `docs/testing.md` |
| กฎ backup 3-2-1 + [ISO/IEC 27001:2022](https://www.iso.org/standard/27001) control 8.13 | backup นอกเครื่องแบบเข้ารหัส, RPO/RTO, ซ้อมกู้ทุกเดือน | `docs/backup.md` |
| [OCI Image Spec](https://github.com/opencontainers/image-spec) | image multi-arch + label `org.opencontainers.image.*` | `.agents/rules/container.md` |
| [The Twelve-Factor App](https://12factor.net/) | config จาก env, log ออก stdout, build/release/run แยกกัน | `AGENTS.md`, `.agents/rules/container.md` |

## กฎหมายไทย

| | ใช้กับ | กฎอยู่ที่ |
|---|---|---|
| พ.ร.บ.คุ้มครองข้อมูลส่วนบุคคล (PDPA) | เก็บข้อมูลส่วนบุคคลเท่าที่จำเป็น, ไม่ log ข้อมูลส่วนบุคคล, ลบ/ส่งออกได้เมื่อเจ้าของขอ | `.agents/rules/api.md` |

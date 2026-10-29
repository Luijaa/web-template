---
name: tailwind4-patterns
description: Use when styling Vue components, adding design tokens or touching dark mode in the web/ SPA (Tailwind CSS 4 with @tailwindcss/vite, CSS-first config).
source: เขียนเองจาก https://tailwindcss.com/docs (หัวข้อ Theme variables, Dark mode, Upgrade guide) (อ่านเมื่อ 2026-10-29) — ต้นแบบ pulse-app (`luija-dev/pulse-app` `6ec2cf0`)
---
# Tailwind CSS 4 (CSS-first)

## 0. ของ v3 ที่ห้ามใช้

Tailwind 4 ไม่ใช้ `tailwind.config.js`, `darkMode: 'class'`, `@tailwind base/components/utilities` และไม่ต้องมี `postcss`/`autoprefixer` — โมเดลมักเขียนแบบ v3 จากความจำ ถ้าไม่แน่ใจเปิด `web/node_modules/tailwindcss/` (CHANGELOG) หรือ upgrade guide ของเวอร์ชันใน `web/package.json`

## 1. ติดตั้ง

```ts
// web/vite.config.ts
import { defineConfig } from 'vite';
import vue from '@vitejs/plugin-vue';
import tailwindcss from '@tailwindcss/vite';

export default defineConfig({ plugins: [vue(), tailwindcss()] });
```

```css
/* web/src/style.css */
@import "tailwindcss";
```

## 2. dark mode 3 โหมด (`system`/`light`/`dark` ตาม `docs/ui.md`)

```css
@custom-variant dark {
  &:where([data-theme="dark"], [data-theme="dark"] *) {
    @slot;
  }
  @media (prefers-color-scheme: dark) {
    &:where(:root:not([data-theme="light"]), :root:not([data-theme="light"]) *) {
      @slot;
    }
  }
}
```

- ไม่มี `data-theme` = ตามระบบ; `data-theme="light"`/`"dark"` = ผู้ใช้เลือกเอง
- `index.html`: `<meta name="color-scheme" content="light dark">`; ตั้ง `data-theme` ก่อน CSS โหลดด้วย `<script src="/theme-init.js"></script>` (ไฟล์ใน `web/public/` — CSP ห้าม inline script) กันจอกระพริบ

## 3. token

```css
@theme {
  --color-primary: #047857;
  --color-surface: #ffffff;
  --color-surface-muted: #f1f5f9;
  --color-text: #0f172a;
  --color-text-muted: #475569;
}

@layer base {
  :root[data-theme="dark"] {
    --color-surface: #0f172a;
    --color-surface-muted: #1e293b;
    --color-text: #f8fafc;
    --color-text-muted: #94a3b8;
  }
  @media (prefers-color-scheme: dark) {
    :root:not([data-theme="light"]) {
      --color-surface: #0f172a;
      --color-surface-muted: #1e293b;
      --color-text: #f8fafc;
      --color-text-muted: #94a3b8;
    }
  }
}
```

- `@theme` สร้าง utility ให้อัตโนมัติ: `bg-surface`, `text-text-muted`, `bg-primary` — ใช้ชื่อ token ใน component ไม่ใช่สีตรง (`bg-slate-900`) ยกเว้นจุดที่ design กำหนด
- สีที่เปลี่ยนตาม theme ใส่ใน token ชุดเดียว แล้ว component ไม่ต้องมี `dark:` ซ้ำทุกที่; `dark:` ใช้กับกรณีพิเศษ
- ค่าเปลี่ยน runtime (เช่น สีกราฟ) อ่านจาก `getComputedStyle(document.documentElement).getPropertyValue('--color-primary')` แทนการ copy ค่าสีไว้ใน TS
- contrast ทั้ง light และ dark ผ่าน WCAG 2.2 AA (ข้อความ 4.5:1, UI 3:1)

## 4. ใน component

```vue
<button
  type="button"
  class="inline-flex items-center gap-2 rounded-lg bg-primary px-4 py-2 text-sm font-medium text-white
         hover:opacity-90 focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-primary
         disabled:opacity-50"
>
  {{ t('action.refresh') }}
</button>
```

- ทุกปุ่ม/ลิงก์มี `focus-visible:` ที่มองเห็นได้
- responsive แบบ mobile-first (`sm:` `md:` `lg:`)
- class ที่ประกอบจากตัวแปร (`` `bg-${color}-500` ``) Tailwind หาไม่เจอ — map เป็น class เต็มใน object แทน

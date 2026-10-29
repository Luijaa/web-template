---
name: vue-pinia-patterns
description: Use when writing or changing Vue 3 components, Pinia stores, API calls, i18n text or polling in the web/ SPA (go-vue-spa stack — Vue 3.5, Pinia 4, TypeScript 6, Vite 8).
source: เขียนเองจาก https://vuejs.org/guide/, https://pinia.vuejs.org/, https://vite.dev/guide/ (อ่านเมื่อ 2026-10-29) — ต้นแบบ pulse-app (`luija-dev/pulse-app` `6ec2cf0`)
---
# Vue 3 + Pinia ใน SPA ที่ embed ใน Go

## 0. เวอร์ชันก่อนเขียน

ดูเวอร์ชันใน `web/package.json` — Pinia 4, Vite 8, TypeScript 6 ใหม่กว่าที่โมเดลมักจำได้: API ที่ไม่มีตัวอย่างใน repo ให้เปิด `web/node_modules/<pkg>/dist/*.d.ts` และ `CHANGELOG.md` ของ package นั้นก่อนเขียน; `bun --cwd=web run lint` (vue-tsc + eslint `no-deprecated`) ต้องผ่าน — ห้ามลดเวอร์ชันหรือปิดกฎเพื่อให้ผ่าน

## 1. component

```vue
<script setup lang="ts">
import { computed, onMounted, onUnmounted, ref } from 'vue';
import { t } from '../i18n';

const props = withDefaults(defineProps<{ itemId: string; refreshSeconds?: number }>(), {
  refreshSeconds: 30,
});
const emit = defineEmits<{ updated: [id: string] }>();

const open = ref(false);                                  // UI state อยู่ใน component
const title = computed(() => t('item.title', { id: props.itemId }));
</script>
```

- `<script setup lang="ts">` ทุกไฟล์; props/emits แบบ type
- ข้อความทุกตัวผ่าน `t()` — ไม่มีข้อความไทย/อังกฤษ hardcode ใน template (lint `check-i18n.js` เทียบ key ทุกภาษา)
- แสดงสถานะจาก API ผ่าน `t('status.<code>')` ไม่แสดงรหัสดิบ
- ปุ่มเป็น `<button>`, input มี `<label>`, modal ปิดด้วย Esc และคืน focus (WCAG 2.2 AA — `docs/ui.md`)

## 2. store (setup store)

```ts
import { defineStore } from 'pinia';
import { computed, ref } from 'vue';
import { apiFetch } from '../api';

export const useItemStore = defineStore('items', () => {
  const items = ref<Item[]>([]);
  const loading = ref(false);
  const error = ref<string | null>(null);         // เก็บ code จาก problem+json ไว้แปล ไม่ใช่ข้อความดิบ

  const activeCount = computed(() => items.value.filter((i) => i.status === 'active').length);

  async function fetchItems(): Promise<void> {
    loading.value = true;
    error.value = null;
    try {
      items.value = await apiFetch<Item[]>('/api/v1/items');
    } catch (e: unknown) {
      error.value = e instanceof ApiError ? e.code : 'network';
    } finally {
      loading.value = false;
    }
  }

  return { items, loading, error, activeCount, fetchItems };
});
```

- ข้อมูลโดเมนอยู่ใน store; สถานะหน้าจอ (modal เปิด/ปิด, ฟอร์มที่ยังไม่ส่ง) อยู่ใน component
- ใน component ใช้ `storeToRefs(store)` กับ state/getter (destructure ตรง ๆ เสีย reactivity); action destructure ได้

## 3. เรียก API

- ฟังก์ชันกลางตัวเดียว (`web/src/api.ts`): `fetch` path แบบ relative (`/api/v1/...` — dev ผ่าน `vite.config.ts` proxy, prod เป็น origin เดียวกัน), `credentials: 'same-origin'`, อ่าน `application/problem+json` แล้ว throw `ApiError` ที่มี `status` + `code`
- 401 → พาไปหน้า login พร้อม `next=`; ห้ามเก็บ token ใน `localStorage` (session ใช้ cookie `HttpOnly` จาก server)
- input ที่ส่งไป validate ฝั่ง client เพื่อ UX เท่านั้น — server ต้อง validate เองเสมอ

## 4. polling และ cleanup

```ts
let timer: ReturnType<typeof setInterval> | undefined;
onMounted(async () => {
  await store.fetchItems();
  timer = setInterval(() => void store.fetchItems(), props.refreshSeconds * 1000);
});
onUnmounted(() => clearInterval(timer));
```

- ทุก `setInterval`/`addEventListener`/`AbortController` มีตัวยกเลิกใน `onUnmounted`
- หน้าที่ซ่อนอยู่ (`document.hidden`) ไม่ต้อง poll ถี่

## 5. i18n, theme, storage

- ภาษา: `setLocale()` ตั้ง cookie `locale` + `document.documentElement.lang`; วันที่/ตัวเลขใช้ `Intl` ที่ระบุ `timeZone: 'Asia/Bangkok'` และปฏิทินสำหรับ `th` ตาม `docs/ui.md`
- theme: ตั้ง/ลบ `data-theme` บน `<html>` (`system` = ลบ attribute) — class ตาม skill `tailwind4-patterns`
- `localStorage`/`sessionStorage` ครอบ `try/catch` ทุกครั้ง (private mode หรือถูกบล็อกจะ throw) และหน้าจอต้องทำงานได้แม้อ่านไม่ได้

## 6. test

- พฤติกรรมที่ผู้ใช้เห็นทดสอบด้วย Playwright (`e2e/`, skill `e2e-playwright`) บน production image — selector ใช้ role/label ไม่ใช่ class ของ Tailwind
- ทุก PR ที่เพิ่มหน้าจอ: e2e ทั้ง `th` และ `en`, light และ dark

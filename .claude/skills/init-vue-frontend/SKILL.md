---
name: init-vue-frontend
description: 使用 Vue 官方 CLI (create-vue) 初始化 Vue 3 + TypeScript + Vue Router + Pinia + Tailwind CSS 前端專案。適用於需要快速建立標準化 Vue 3 SPA 的場景，支援 monorepo 與獨立專案兩種模式。
---

# Init Vue Frontend

使用官方 Vue CLI (`create-vue`) 初始化一個 Vue 3 + Vite + TypeScript + Vue Router + Pinia + Tailwind CSS 前端專案。

## 執行前確認

在開始前，先詢問使用者以下資訊（若已在對話中提供則跳過）：

1. **專案目錄名稱**：前端資料夾名稱（預設：`frontend`）
2. **是否在 monorepo 內**：若是，CLI 要在 monorepo root 執行

> Vue Router、Pinia、TypeScript 為**預設安裝**，由 CLI flag 一次指定，不需手動設定。

## 執行步驟

### Step 1：CLI 建立專案（含 Router + Pinia）

在正確的目錄下執行：

```bash
npm create vue@latest {專案目錄名稱} -- --typescript --router --pinia
```

CLI 會自動生成包含以下內容的完整專案結構：
- `vite.config.ts`
- `tsconfig.json`
- `src/main.ts`（已整合 Router + Pinia）
- `src/router/index.ts`
- `src/stores/counter.ts`（Pinia 範例 store）
- `src/views/HomeView.vue`、`AboutView.vue`

> 絕對不要手動建立上述任何 boilerplate 檔案，一律由 CLI 生成。

### Step 2：安裝 Tailwind CSS

進入專案目錄安裝：

```bash
cd {專案目錄名稱}
npm install -D tailwindcss postcss autoprefixer
```

使用 Tailwind CLI 初始化設定檔：

```bash
npx tailwindcss init -p
```

確認 `tailwind.config.js` 與 `postcss.config.js` 由 CLI 自動生成。

### Step 3：配置 Tailwind content 路徑

修改 `tailwind.config.js`：

```js
/** @type {import('tailwindcss').Config} */
export default {
  content: [
    "./index.html",
    "./src/**/*.{vue,js,ts,jsx,tsx}",
  ],
  theme: {
    extend: {},
  },
  plugins: [],
}
```

### Step 4：加入 Tailwind Directives

在 `src/assets/main.css` 的**最頂部**加入：

```css
@tailwind base;
@tailwind components;
@tailwind utilities;
```

確認 `src/main.ts` 有 import 此 CSS 檔案（`create-vue` 預設已 import `./assets/main.css`）。

### Step 5：確認 package.json name 欄位

若在 monorepo 環境，確認 `package.json` 的 `name` 欄位與 root workspace 設定一致：

```json
{
  "name": "{專案目錄名稱}"
}
```

### Step 6：驗收

```bash
npm run build
```

確認：
- Vite 無 TypeScript 編譯錯誤
- Tailwind CSS 正確 purge
- `npm run dev` 啟動開發伺服器無錯誤，Router 路由可正常切換

## 注意事項

- 若專案在 monorepo 內，後續安裝套件應從根目錄使用 `npm install {pkg} --workspace={專案目錄名稱}`
- Tailwind 設定的 `content` 路徑必須包含 `.vue` 副檔名，否則 class 會被 purge 掉
- 不要刪除 CLI 生成的 `tsconfig.node.json`，Vite 需要它處理設定檔的 TypeScript 解析
- `create-vue` 生成的 `src/stores/counter.ts` 為範例檔案，可依需求刪除或保留

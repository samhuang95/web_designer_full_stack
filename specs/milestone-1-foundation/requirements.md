# Requirements: Milestone 1 — Foundation

## Overview

建立 monorepo 骨架與最小可行後端管線：接收自然語言 prompt → 關鍵字分類 → 建立 session 紀錄 → 建立輸出目錄結構。本里程碑不含 AI API、不含前台 UI、不含實際程式碼生成。

---

## User Stories & Acceptance Criteria

### US-1: Monorepo Workspace

**As a developer,** I want a single root `package.json` using npm workspaces so that I can manage all packages from one location.

- **AC-1.1** 執行根目錄 `npm install`，npm 識別 `workspaces: ["backend", "frontend"]` 且不報錯
- **AC-1.2** `.gitignore` 排除 `node_modules/`、`dist/`、`generated/`、`*.db`、`.env*`
- **AC-1.3** `generated/` 目錄存在並含 `.gitkeep`，git 追蹤目錄但忽略內容

---

### US-2: NestJS Backend with Fastify Adapter

**As a developer,** I want a NestJS application with Fastify adapter so that the backend has high-throughput HTTP performance.

- **AC-2.1** `npx @nestjs/cli new backend` 產生 `backend/` 標準結構
- **AC-2.2** `main.ts` 使用 `FastifyAdapter`，API base path 為 `/api/v1`，監聽 port `3000`
- **AC-2.3** 全域啟用 `ValidationPipe`（`whitelist: true`, `forbidNonWhitelisted: true`, `transform: true`）
- **AC-2.4** 所有回應格式統一為 `{ data, meta: {}, error: null }`（全域 interceptor）
- **AC-2.5** 所有錯誤格式統一為 `{ data: null, meta: {}, error: { statusCode, message } }`（全域 filter）
- **AC-2.6** 執行 `npm run start:dev` 無 TypeScript 編譯錯誤

---

### US-3: Drizzle ORM + SQLite

**As a developer,** I want Drizzle ORM connected to SQLite so that the system has a persistent store for generation sessions.

- **AC-3.1** `backend/drizzle.config.ts` 存在，指向 `./data/app.db`
- **AC-3.2** `backend/src/database/schema/sessions.schema.ts` 定義 `generation_sessions` 表（欄位見設計文件）
- **AC-3.3** `npx drizzle-kit generate` 產生 migration SQL 至 `src/database/migrations/`
- **AC-3.4** `npx drizzle-kit migrate` 建立 `data/app.db` 且表結構正確
- **AC-3.5** `npx drizzle-kit introspect` 輸出 TypeScript 類型至 `src/generated-types/`

---

### US-4: StorageModule

**As a developer,** I want a `StorageModule` with an abstract interface so that storage implementation can be swapped later.

- **AC-4.1** `nest generate module modules/storage` + `nest generate service modules/storage` 產生標準檔案
- **AC-4.2** `IStorageService` interface 定義：`createSession`、`getSession`、`updateSessionStatus`
- **AC-4.3** `StorageService` 實作三個方法，使用 Drizzle ORM 操作 `generation_sessions`
- **AC-4.4** `StorageModule` 為 `@Global()` module
- **AC-4.5** `StorageService` 單元測試（in-memory SQLite）全部通過

---

### US-5: ClassifierModule

**As a system,** I want keyword-based classification so that website type is determined without any external API call.

- **AC-5.1** `nest generate module modules/classifier` + `nest generate service modules/classifier`
- **AC-5.2** `classifier.config.ts` 定義 5 個分類：`blog`、`portfolio`、`e-commerce`、`corporate`、`landing-page`
- **AC-5.3** `classify(prompt)` 大小寫不敏感，命中最多關鍵字的分類勝出
- **AC-5.4** 無關鍵字命中時回傳預設值 `'landing-page'`
- **AC-5.5** 相同命中數時以 priority 數字最小者勝出
- **AC-5.6** 單元測試覆蓋：命中、未命中、大小寫、tie-break 四個情境

---

### US-6: POST /generate Endpoint

**As a user,** I want to POST a prompt to `/api/v1/generate` and receive a session ID.

- **AC-6.1** `nest generate module/controller/service modules/generator` 建立標準結構
- **AC-6.2** `GenerateDto` 以 class-validator 驗證 `prompt` 為非空字串
- **AC-6.3** 驗證失敗回傳 HTTP 400
- **AC-6.4** 成功回傳 HTTP 202：`{ data: { sessionId, websiteType, status: 'pending' }, meta: {}, error: null }`
- **AC-6.5** 回傳的 `sessionId` 可立即被 `StorageService.getSession()` 查到

---

### US-7: Generated Directory Structure

**As the system,** I want to create `generated/{slug}_{timestamp}/frontend|backend|database/` when a session starts.

- **AC-7.1** 目錄命名格式：`{websiteType-kebab-case}_{unix-timestamp-ms}`
- **AC-7.2** 三個子目錄：`frontend/`、`backend/`、`database/` 皆被建立
- **AC-7.3** 成功後 `output_path` 被寫入 session 紀錄
- **AC-7.4** 目錄建立失敗時 session status 設為 `'failed'`，回傳 HTTP 500

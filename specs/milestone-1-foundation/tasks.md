# Tasks: Milestone 1 — Foundation

## 執行邏輯說明

正確的 CLI-First 建立順序：

```
Step 1: 用官方 CLI 建立 backend/ 和 frontend/ 目錄（不手動建立任何 boilerplate）
Step 2: 設定 monorepo root package.json workspace 指向已建立的目錄
Step 3: 根目錄執行 npm install，讓 npm workspaces 連結各套件
Step 4: 各自配置（Fastify adapter、Tailwind、Drizzle...）
```

## 執行階段與並行關係

```
Phase A（循序）: [Task 1: CLI scaffold backend + frontend]
                          │
Phase B（循序）: [Task 2: monorepo root 設定 + npm install]
                      ┌───┴───┐
Phase C（並行）: [Task 3]   [Task 4]
                後端配置    前台 Tailwind 配置
                   │
Phase D（循序）: [Task 5: Drizzle ORM]
                   │
Phase E（循序）: [Task 6: DatabaseModule]
                 ┌──┴──┐
Phase F（並行）: [Task 7] [Task 8]
              Storage   Classifier
                 └──┬──┘
Phase G（循序）: [Task 9: GeneratorModule + POST /generate]
                   │
Phase H（最後）: [Task 10: 整合驗收]
```

---

## Task 1 — CLI Scaffold：建立 backend/ 與 frontend/ 目錄
**依賴：** 無（第一步）

> 用官方 CLI 建立兩個子專案目錄。CLI 會自動生成各自的 `package.json`、`tsconfig.json` 與標準結構，不手動建立任何檔案。

- [ ] 1.1 在 monorepo 根目錄執行 NestJS CLI，建立後端：
  ```bash
  npx @nestjs/cli new backend --package-manager npm --skip-git
  ```
  確認 `backend/` 目錄已建立，含 `src/main.ts`、`src/app.module.ts`、`package.json`

- [ ] 1.2 在 monorepo 根目錄執行 Vite CLI，建立前端：
  ```bash
  npm create vite@latest frontend -- --template vue-ts
  ```
  確認 `frontend/` 目錄已建立，含 `src/main.ts`、`vite.config.ts`、`package.json`

- [ ] **驗收：** `backend/` 與 `frontend/` 目錄皆存在，各自的 `package.json` 由 CLI 自動生成

---

## Task 2 — Monorepo Root 設定 + npm install
**依賴：** Task 1

> CLI 已建立子目錄後，才設定 root workspace 指向它們，再執行 `npm install`。

- [ ] 2.1 在根目錄建立 `package.json`：
  ```json
  {
    "name": "web-designer-full-stack",
    "private": true,
    "workspaces": ["backend", "frontend"],
    "scripts": {
      "dev:backend": "npm run start:dev --workspace=backend",
      "dev:frontend": "npm run dev --workspace=frontend",
      "build": "npm run build --workspaces",
      "test": "npm run test --workspace=backend"
    }
  }
  ```

- [ ] 2.2 更新根目錄 `.gitignore`，加入：
  ```
  node_modules/
  dist/
  generated/*
  !generated/.gitkeep
  *.db
  .env
  .env.*
  backend/data/
  ```

- [ ] 2.3 建立 `generated/.gitkeep`（確保 git 追蹤此目錄但忽略其內容）

- [ ] 2.4 在根目錄執行：
  ```bash
  npm install
  ```
  npm workspaces 會自動連結 `backend/` 與 `frontend/` 的依賴

- [ ] **驗收：** 根目錄 `node_modules/` 建立，`backend/` 與 `frontend/` 被識別為 workspace packages

---

## Task 3 — NestJS 後端配置（Fastify + 全域中介層）
**依賴：** Task 2 | **可與 Task 4 並行**

> 在 CLI 已建立的 NestJS 專案上進行配置，不重新建立 boilerplate。

- [ ] 3.1 在 `backend/` 安裝 Fastify adapter：
  ```bash
  npm install @nestjs/platform-fastify --workspace=backend
  ```

- [ ] 3.2 修改 `backend/src/main.ts`：
  - 改用 `FastifyAdapter`
  - 設定 `app.setGlobalPrefix('api/v1')`
  - 監聽 port `3000`

- [ ] 3.3 在 `main.ts` 啟用全域 `ValidationPipe`：
  ```typescript
  app.useGlobalPipes(new ValidationPipe({
    whitelist: true,
    forbidNonWhitelisted: true,
    transform: true,
  }));
  ```

- [ ] 3.4 建立 `backend/src/common/interceptors/response-wrapper.interceptor.ts`：
  實作 `NestInterceptor`，包裝成功回應為 `{ data, meta: {}, error: null }`

- [ ] 3.5 建立 `backend/src/common/filters/http-exception.filter.ts`：
  實作 `ExceptionFilter`，包裝 HttpException 為 `{ data: null, meta: {}, error: { statusCode, message } }`

- [ ] 3.6 在 `main.ts` 全域註冊：
  ```typescript
  app.useGlobalInterceptors(new ResponseWrapperInterceptor());
  app.useGlobalFilters(new HttpExceptionFilter());
  ```

- [ ] **驗收：** 在 `backend/` 執行 `npm run start:dev`，服務啟動無 TypeScript 編譯錯誤

---

## Task 4 — 前台 Tailwind CSS 配置
**依賴：** Task 2 | **可與 Task 3 並行**

> 在 Vite CLI 已建立的 Vue 3 專案上配置 Tailwind，不重新建立 Vue 結構。

- [ ] 4.1 在 `frontend/` 安裝 Tailwind：
  ```bash
  npm install -D tailwindcss postcss autoprefixer --workspace=frontend
  ```

- [ ] 4.2 在 `frontend/` 執行 Tailwind CLI 初始化：
  ```bash
  npx tailwindcss init -p --prefix frontend/
  ```
  或進入目錄執行：`cd frontend && npx tailwindcss init -p`
  確認 `tailwind.config.js` 與 `postcss.config.js` 由 CLI 自動生成

- [ ] 4.3 修改 `frontend/tailwind.config.js` 的 `content`：
  ```js
  content: ["./index.html", "./src/**/*.{vue,ts}"]
  ```

- [ ] 4.4 在 `frontend/src/style.css` 加入三個 Tailwind directives：
  ```css
  @tailwind base;
  @tailwind components;
  @tailwind utilities;
  ```

- [ ] **驗收：** 在 `frontend/` 執行 `npm run build`，Vite 無錯誤完成編譯

---

## Task 5 — Drizzle ORM + SQLite 設定
**依賴：** Task 3

- [ ] 5.1 在 `backend/` 安裝套件：
  ```bash
  npm install drizzle-orm better-sqlite3 --workspace=backend
  npm install -D drizzle-kit @types/better-sqlite3 --workspace=backend
  ```

- [ ] 5.2 在 `backend/` 執行 Drizzle Kit 初始化：
  ```bash
  cd backend && npx drizzle-kit init
  ```
  若 CLI 不支援 `init` 指令，手動建立 `backend/drizzle.config.ts`：
  ```typescript
  export default {
    dialect: 'sqlite',
    schema: './src/database/schema',
    out: './src/database/migrations',
    dbCredentials: { url: './data/app.db' },
  };
  ```

- [ ] 5.3 建立 `backend/data/` 目錄（`mkdir -p backend/data`）

- [ ] 5.4 建立 `backend/src/database/schema/sessions.schema.ts`（欄位見 design.md 第 2 節）

- [ ] 5.5 在 `backend/package.json` scripts 加入：
  ```json
  "db:generate": "drizzle-kit generate",
  "db:migrate": "drizzle-kit migrate",
  "db:introspect": "drizzle-kit introspect"
  ```

- [ ] 5.6 執行 migration：
  ```bash
  cd backend && npm run db:generate
  cd backend && npm run db:migrate
  ```
  確認 `src/database/migrations/` 有 SQL 檔案，`data/app.db` 建立

- [ ] 5.7 執行反向工程（驗證 DB First 流程）：
  ```bash
  cd backend && npm run db:introspect
  ```
  確認 TypeScript 類型輸出至 `src/generated-types/`

- [ ] **驗收：** `app.db` 可查詢，`generation_sessions` 表結構正確

---

## Task 6 — DatabaseModule
**依賴：** Task 5

- [ ] 6.1 建立 `backend/src/database/database.module.ts`（非 NestJS CLI 標準路徑，手動建立）

- [ ] 6.2 定義 `DRIZZLE_DB = 'DRIZZLE_DB'` 常數並 export

- [ ] 6.3 建立 provider：
  ```typescript
  {
    provide: DRIZZLE_DB,
    useFactory: () => {
      const client = betterSqlite3('data/app.db');
      return drizzle(client);
    },
  }
  ```

- [ ] 6.4 module 加上 `@Global()` decorator，`exports: [DRIZZLE_DB]`

- [ ] 6.5 在 `app.module.ts` imports 加入 `DatabaseModule`

- [ ] **驗收：** 後端啟動無 DI 錯誤

---

## Task 7 — StorageModule
**依賴：** Task 6 | **可與 Task 8 並行**

- [ ] 7.1 執行 NestJS CLI（在 `backend/` 目錄下）：
  ```bash
  nest generate module modules/storage
  nest generate service modules/storage --no-spec
  ```

- [ ] 7.2 建立 `interfaces/storage.interface.ts`：
  定義 `IStorageService`、`GenerationSession` 類型、`SessionStatus` enum（`pending | processing | done | failed`）

- [ ] 7.3 建立 `dto/storage.dto.ts`：定義 `CreateSessionDto`（`sessionId`、`prompt`、`websiteType`）

- [ ] 7.4 `StorageService` 注入 `@Inject(DRIZZLE_DB)` 並實作三個方法

- [ ] 7.5 `storage.module.ts` 加上 `@Global()`，`exports: [StorageService]`

- [ ] 7.6 在 `app.module.ts` imports 加入 `StorageModule`

- [ ] 7.7 建立 `storage.service.spec.ts`：使用 in-memory SQLite（`:memory:`）測試三個方法

- [ ] **驗收：** `npm test` StorageService 測試全部通過

---

## Task 8 — ClassifierModule
**依賴：** Task 6 | **可與 Task 7 並行**

- [ ] 8.1 執行 NestJS CLI（在 `backend/` 目錄下）：
  ```bash
  nest generate module modules/classifier
  nest generate service modules/classifier --no-spec
  ```

- [ ] 8.2 建立 `interfaces/classifier.interface.ts`：定義 `ClassifierRule`、`ClassifierConfig` 類型

- [ ] 8.3 建立 `classifier.config.ts`（5 個分類規則 + `DEFAULT_TYPE`，見 design.md 第 3 節）

- [ ] 8.4 實作 `ClassifierService.classify(prompt: string): string`：
  轉小寫 → 計算各分類 keyword 命中數 → 取最高（tie 時 priority 最小優先）→ 無命中回傳 `DEFAULT_TYPE`

- [ ] 8.5 `classifier.module.ts` exports `ClassifierService`

- [ ] 8.6 建立 `classifier.service.spec.ts`：測試（a）單一命中、（b）大小寫不敏感、（c）無命中預設、（d）tie-break

- [ ] **驗收：** `npm test` ClassifierService 測試全部通過

---

## Task 9 — GeneratorModule + POST /generate
**依賴：** Task 7 + Task 8

- [ ] 9.1 執行 NestJS CLI（在 `backend/` 目錄下）：
  ```bash
  nest generate module modules/generator
  nest generate controller modules/generator --no-spec
  nest generate service modules/generator --no-spec
  ```

- [ ] 9.2 安裝 config 套件：
  ```bash
  npm install @nestjs/config --workspace=backend
  ```

- [ ] 9.3 在 `app.module.ts` 引入 `ConfigModule.forRoot({ isGlobal: true })`

- [ ] 9.4 建立 `backend/.env`：
  ```
  GENERATED_DIR=../generated
  PORT=3000
  ```

- [ ] 9.5 建立 `dto/generate.dto.ts`：
  ```typescript
  @IsString() @IsNotEmpty() prompt: string
  ```

- [ ] 9.6 `generator.module.ts` imports 加入 `ClassifierModule`

- [ ] 9.7 實作 `GeneratorService.generate(dto)`：
  - `classify(prompt)` → `websiteType`
  - `crypto.randomUUID()` → `sessionId`（Node >= 20 原生）
  - `StorageService.createSession()`
  - `fs.mkdirSync()` 建立 `{GENERATED_DIR}/{slug}_{ts}/frontend|backend|database/`
  - 成功 → `updateSessionStatus('pending', outputPath)` → return
  - 失敗 → `updateSessionStatus('failed')` → throw `InternalServerErrorException`

- [ ] 9.8 `GeneratorController`：`@Post() @HttpCode(202)` 呼叫 `GeneratorService.generate(dto)`

- [ ] 9.9 在 `app.module.ts` imports 加入 `GeneratorModule`

- [ ] **驗收（手動 curl）：**
  ```bash
  curl -X POST http://localhost:3000/api/v1/generate \
    -H "Content-Type: application/json" \
    -d '{"prompt":"I want a blog for my travel adventures"}'
  ```
  - 回傳 HTTP 202，`data.websiteType` 為 `"blog"`
  - `generated/blog_{timestamp}/frontend/`、`backend/`、`database/` 目錄存在
  - SQLite `generation_sessions` 有對應 row

---

## Task 10 — 整合驗收
**依賴：** 所有前述任務

- [ ] 10.1 根目錄 `npm install` 無錯誤，workspace 正確識別
- [ ] 10.2 `backend/` 執行 `npm run build` 無 TypeScript 錯誤
- [ ] 10.3 `backend/` 執行 `npm test`，所有單元測試通過
- [ ] 10.4 `frontend/` 執行 `npm run build` 無錯誤
- [ ] 10.5 手動測試 POST /generate（正常 + 空 prompt 400 錯誤情境）
- [ ] 10.6 確認 `generated/` 下有正確的三層子目錄
- [ ] 10.7 更新 `README.md`，加入本地開發啟動步驟

---

## 技術決策（已確認）

| # | 決策項目 | 確認結果 |
|---|----------|----------|
| 1 | **Node.js 版本** | >= 20，使用 NVM 管理版本，原生 `crypto.randomUUID()` |
| 2 | **`generated/` 路徑** | 相對路徑：`GENERATED_DIR=../generated`（相對於 `backend/`） |
| 3 | **Migration 時機** | 手動 CLI 執行（`npm run db:migrate`） |
| 4 | **StorageService 測試** | in-memory SQLite（`:memory:`），測試真實 ORM 查詢 |
| 5 | **`@nestjs/config`** | M1 一併引入 |

# Technical Design: Milestone 1 — Foundation

## 1. Monorepo 目錄結構

```
web_designer_full_stack/
├── package.json                        # root workspace: ["backend", "frontend"]
├── .gitignore
├── specs/
│   └── milestone-1-foundation/
├── backend/
│   ├── package.json
│   ├── tsconfig.json
│   ├── drizzle.config.ts
│   ├── data/
│   │   └── app.db                      # SQLite 檔案（git-ignored）
│   └── src/
│       ├── main.ts                     # FastifyAdapter, port 3000, /api/v1
│       ├── app.module.ts
│       ├── database/
│       │   ├── database.module.ts      # @Global(), 提供 DRIZZLE_DB token
│       │   ├── schema/
│       │   │   └── sessions.schema.ts
│       │   └── migrations/             # drizzle-kit generate 輸出
│       ├── generated-types/            # drizzle-kit introspect 輸出
│       ├── common/
│       │   ├── interceptors/
│       │   │   └── response-wrapper.interceptor.ts
│       │   └── filters/
│       │       └── http-exception.filter.ts
│       └── modules/
│           ├── storage/
│           │   ├── storage.module.ts   # @Global()
│           │   ├── storage.service.ts
│           │   ├── dto/storage.dto.ts
│           │   └── interfaces/storage.interface.ts
│           ├── classifier/
│           │   ├── classifier.module.ts
│           │   ├── classifier.service.ts
│           │   ├── classifier.config.ts
│           │   └── interfaces/classifier.interface.ts
│           └── generator/
│               ├── generator.module.ts
│               ├── generator.controller.ts
│               ├── generator.service.ts
│               └── dto/generate.dto.ts
├── frontend/                           # Vite shell only（M1 不含 UI）
│   ├── package.json
│   ├── vite.config.ts
│   ├── tailwind.config.js
│   └── src/
└── generated/                          # 執行期輸出（git-ignored）
    └── {slug}_{timestamp}/
        ├── frontend/
        ├── backend/
        └── database/
```

---

## 2. 資料模型

### Table: `generation_sessions`

| 欄位         | 類型    | 約束                          | 說明                               |
|--------------|---------|-------------------------------|------------------------------------|
| id           | integer | PRIMARY KEY AUTOINCREMENT     |                                    |
| session_id   | text    | UNIQUE NOT NULL               | UUID v4                            |
| prompt       | text    | NOT NULL                      | 使用者原始輸入                     |
| website_type | text    | NOT NULL                      | ClassifierService 的輸出           |
| status       | text    | NOT NULL, DEFAULT 'pending'   | pending / processing / done / failed |
| output_path  | text    | nullable                      | 生成目錄的絕對路徑                 |
| created_at   | integer | NOT NULL                      | Unix epoch 毫秒                    |
| updated_at   | integer | NOT NULL                      | Unix epoch 毫秒                    |

**Drizzle Schema 定義**（`sessions.schema.ts`）：
```typescript
import { sqliteTable, text, integer } from 'drizzle-orm/sqlite-core';

export const generationSessions = sqliteTable('generation_sessions', {
  id: integer('id').primaryKey({ autoIncrement: true }),
  sessionId: text('session_id').unique().notNull(),
  prompt: text('prompt').notNull(),
  websiteType: text('website_type').notNull(),
  status: text('status').notNull().default('pending'),
  outputPath: text('output_path'),
  createdAt: integer('created_at').notNull(),
  updatedAt: integer('updated_at').notNull(),
});
```

---

## 3. 模組設計

### DatabaseModule
- `@Global()` — 全域提供 `DRIZZLE_DB` token
- `useFactory`：開啟 `better-sqlite3` 連線到 `data/app.db`，以 `drizzle()` 包裝後提供

### StorageModule
- `@Global()` — 全域提供 `StorageService`
- `IStorageService` interface：
  ```typescript
  interface IStorageService {
    createSession(data: CreateSessionDto): Promise<GenerationSession>;
    getSession(sessionId: string): Promise<GenerationSession | null>;
    updateSessionStatus(sessionId: string, status: SessionStatus, outputPath?: string): Promise<void>;
  }
  ```

### ClassifierModule
- 無 DB 依賴，純記憶體規則比對
- `classifier.config.ts` 關鍵字配置：
  ```typescript
  export const CLASSIFIER_CONFIG = [
    { type: 'blog',         priority: 1, keywords: ['blog','article','post','write','journal','news'] },
    { type: 'portfolio',    priority: 2, keywords: ['portfolio','showcase','gallery','resume','cv'] },
    { type: 'e-commerce',   priority: 3, keywords: ['shop','store','product','buy','cart','payment'] },
    { type: 'corporate',    priority: 4, keywords: ['company','corporate','business','enterprise'] },
    { type: 'landing-page', priority: 5, keywords: ['landing','promo','campaign','signup','waitlist'] },
  ];
  export const DEFAULT_TYPE = 'landing-page';
  ```
- Tie-break：priority 數字**最小**者優先

### GeneratorModule
- 依賴：`ClassifierModule`（import）、`StorageModule`（global）、`@nestjs/config`
- `generate()` 流程：
  ```
  classify(prompt) → randomUUID() → createSession() → mkdirSync(3 sub-dirs) → updateSessionStatus()
  ```
- 目錄路徑由環境變數 `GENERATED_DIR` 控制（預設 `../generated` 相對於 `backend/`）

---

## 4. API 合約

### POST /api/v1/generate

**Request Body:**
```json
{ "prompt": "I want a blog for my travel adventures" }
```

**Response 202:**
```json
{
  "data": {
    "sessionId": "550e8400-e29b-41d4-a716-446655440000",
    "websiteType": "blog",
    "status": "pending"
  },
  "meta": {},
  "error": null
}
```

**Response 400:**
```json
{
  "data": null,
  "meta": {},
  "error": { "statusCode": 400, "message": ["prompt should not be empty"] }
}
```

**Response 500:**
```json
{
  "data": null,
  "meta": {},
  "error": { "statusCode": 500, "message": "Failed to create output directory" }
}
```

---

## 5. 請求流程圖

```
POST /api/v1/generate
        │
        ▼
GeneratorController（ValidationPipe 驗證 DTO）
        │
        ▼
GeneratorService.generate()
        │
        ├─► ClassifierService.classify(prompt) ──► websiteType
        │
        ├─► crypto.randomUUID() ──► sessionId
        │
        ├─► StorageService.createSession()
        │
        ├─► fs.mkdirSync(generated/{slug}_{ts}/frontend|backend|database)
        │
        ├─► [成功] StorageService.updateSessionStatus('pending', outputPath)
        │           └─► return { sessionId, websiteType, status }
        │
        └─► [失敗] StorageService.updateSessionStatus('failed')
                    └─► throw InternalServerErrorException
```

---

## 6. 技術決策

| 決策項目 | 選擇 | 理由 |
|----------|------|------|
| HTTP adapter | Fastify | 效能優於 Express |
| Session UUID | `crypto.randomUUID()` (Node 20+，NVM 管理) | 無額外依賴，不需安裝 `uuid` 套件 |
| 目錄建立 | `fs.mkdirSync({ recursive: true })` | 同步即可，M1 不需非同步 |
| Migration 執行 | CLI-only，手動執行 `npm run db:migrate` | 降低 M1 複雜度，M2 再評估自動化 |
| StorageService 測試 | in-memory SQLite (`:memory:`) | 測試真實 ORM 查詢邏輯，不 mock |
| 環境變數 | `@nestjs/config` + `.env`，M1 一併引入 | 避免 M2 重構；`GENERATED_DIR=../generated` |

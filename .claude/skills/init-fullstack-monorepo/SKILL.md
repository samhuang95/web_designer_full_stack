---
name: init-fullstack-monorepo
description: 建立 NestJS + Vue 3 全端 monorepo 專案。依正確順序執行：先用官方 CLI 建立 backend/ 與 frontend/ 目錄，再設定 root package.json workspace，最後執行 npm install。適用於需要從零開始建立全端 monorepo 的場景。
---

# Init Fullstack Monorepo

從零建立一個完整的全端 monorepo 專案，包含 NestJS 後端與 Vue 3 前端。

**重要順序原則：先用 CLI 建立子專案目錄，再設定 monorepo root，最後執行 npm install。**

## 執行前確認

在開始前，先詢問使用者以下資訊（若已在對話中提供則跳過）：

1. **根目錄名稱**：monorepo 根目錄（通常是現有工作目錄）
2. **後端目錄名稱**：預設 `backend`
3. **前端目錄名稱**：預設 `frontend`
4. **API base path**：預設 `api/v1`
5. **後端 Port**：預設 `3000`

> Vue Router 與 Pinia 為**預設安裝**，不需詢問。

## 執行步驟

---

### Phase 1：CLI Scaffold（先建立子專案目錄）

> 這是第一步，必須先完成才能設定 monorepo root。

**Step 1.1 — NestJS CLI 建立後端**

在 monorepo 根目錄執行：

```bash
npx @nestjs/cli new {後端目錄名稱} --package-manager npm --skip-git
```

確認 `{後端目錄名稱}/` 目錄已建立，包含 `src/main.ts`、`src/app.module.ts`、`package.json`。

**Step 1.2 — Vue CLI 建立前端（含 Router + Pinia）**

在 monorepo 根目錄執行：

```bash
npm create vue@latest {前端目錄名稱} -- --typescript --router --pinia
```

確認 `{前端目錄名稱}/` 目錄已建立，包含 `src/main.ts`（已整合 Router + Pinia）、`src/router/index.ts`、`src/stores/`、`vite.config.ts`、`package.json`。

---

### Phase 2：Monorepo Root 設定

> 子專案目錄已存在後，才設定 workspace 指向它們。

**Step 2.1 — 建立根目錄 package.json**

```json
{
  "name": "{根目錄名稱}",
  "private": true,
  "workspaces": ["{後端目錄名稱}", "{前端目錄名稱}"],
  "scripts": {
    "dev:backend": "npm run start:dev --workspace={後端目錄名稱}",
    "dev:frontend": "npm run dev --workspace={前端目錄名稱}",
    "build": "npm run build --workspaces",
    "test": "npm run test --workspace={後端目錄名稱}"
  }
}
```

**Step 2.2 — 更新 .gitignore**

在根目錄的 `.gitignore` 加入：

```
node_modules/
dist/
generated/*
!generated/.gitkeep
*.db
.env
.env.*
{後端目錄名稱}/data/
```

**Step 2.3 — 建立 generated 目錄**

```bash
mkdir -p generated
touch generated/.gitkeep
```

---

### Phase 3：安裝所有依賴

**Step 3.1 — 根目錄執行 npm install**

```bash
npm install
```

npm workspaces 會自動連結 `{後端目錄名稱}/` 與 `{前端目錄名稱}/` 的依賴，並在根目錄的 `node_modules/` 建立 symlink。

**驗收：**
- 根目錄 `node_modules/` 建立
- `{後端目錄名稱}` 與 `{前端目錄名稱}` 出現在 npm workspaces 清單

---

### Phase 4：後端配置

**Step 4.1 — 安裝 Fastify adapter**

```bash
npm install @nestjs/platform-fastify --workspace={後端目錄名稱}
```

**Step 4.2 — 修改 main.ts 使用 Fastify**

修改 `{後端目錄名稱}/src/main.ts`：

```typescript
import { NestFactory } from '@nestjs/core';
import { FastifyAdapter, NestFastifyApplication } from '@nestjs/platform-fastify';
import { ValidationPipe } from '@nestjs/common';
import { AppModule } from './app.module';
import { ResponseWrapperInterceptor } from './common/interceptors/response-wrapper.interceptor';
import { HttpExceptionFilter } from './common/filters/http-exception.filter';

async function bootstrap() {
  const app = await NestFactory.create<NestFastifyApplication>(
    AppModule,
    new FastifyAdapter(),
  );

  app.setGlobalPrefix('{api_base_path}');

  app.useGlobalPipes(new ValidationPipe({
    whitelist: true,
    forbidNonWhitelisted: true,
    transform: true,
  }));

  app.useGlobalInterceptors(new ResponseWrapperInterceptor());
  app.useGlobalFilters(new HttpExceptionFilter());

  await app.listen({port}, '0.0.0.0');
}
bootstrap();
```

**Step 4.3 — CLI 生成 Interceptor 骨架**

```bash
cd {後端目錄名稱}
nest g interceptor common/interceptors/response-wrapper --no-spec --flat
```

CLI 生成骨架後，填入邏輯：

```typescript
import { Injectable, NestInterceptor, ExecutionContext, CallHandler } from '@nestjs/common';
import { Observable } from 'rxjs';
import { map } from 'rxjs/operators';

@Injectable()
export class ResponseWrapperInterceptor implements NestInterceptor {
  intercept(context: ExecutionContext, next: CallHandler): Observable<any> {
    return next.handle().pipe(
      map((data) => ({ data, meta: {}, error: null })),
    );
  }
}
```

**Step 4.4 — CLI 生成 Filter 骨架**

```bash
nest g filter common/filters/http-exception --no-spec --flat
```

CLI 生成骨架後，填入邏輯：

```typescript
import { ExceptionFilter, Catch, ArgumentsHost, HttpException } from '@nestjs/common';
import { FastifyReply } from 'fastify';

@Catch(HttpException)
export class HttpExceptionFilter implements ExceptionFilter {
  catch(exception: HttpException, host: ArgumentsHost) {
    const ctx = host.switchToHttp();
    const reply = ctx.getResponse<FastifyReply>();
    const status = exception.getStatus();
    const exceptionResponse = exception.getResponse();

    reply.status(status).send({
      data: null,
      meta: {},
      error: {
        statusCode: status,
        message:
          typeof exceptionResponse === 'object' && 'message' in exceptionResponse
            ? (exceptionResponse as any).message
            : exception.message,
      },
    });
  }
}
```

---

### Phase 5：前端 Tailwind 配置

**Step 5.1 — 安裝 Tailwind**

```bash
npm install -D tailwindcss postcss autoprefixer --workspace={前端目錄名稱}
```

**Step 5.2 — Tailwind CLI 初始化**

```bash
cd {前端目錄名稱} && npx tailwindcss init -p
```

確認 `tailwind.config.js` 與 `postcss.config.js` 由 CLI 生成。

**Step 5.3 — 配置 content 路徑**

修改 `{前端目錄名稱}/tailwind.config.js`：

```js
export default {
  content: ["./index.html", "./src/**/*.{vue,js,ts,jsx,tsx}"],
  theme: { extend: {} },
  plugins: [],
}
```

**Step 5.4 — 加入 Tailwind Directives**

在 `{前端目錄名稱}/src/style.css` 最頂部加入：

```css
@tailwind base;
@tailwind components;
@tailwind utilities;
```

**Step 5.5 — 確認 Router + Pinia 已由 CLI 生成**

`npm create vue@latest` 已在 Step 1.2 透過 `--router --pinia` flag 自動生成：
- `src/router/index.ts`
- `src/stores/`
- `src/main.ts`（已整合 `app.use(router)` 與 `app.use(createPinia())`）

無需手動安裝或設定，確認這些檔案存在即可。

---

### Phase 6：整合驗收

**後端驗收：**
```bash
cd {後端目錄名稱} && npm run start:dev
```
確認服務啟動無 TypeScript 錯誤。

**前端驗收：**
```bash
cd {前端目錄名稱} && npm run build
```
確認 Vite 無錯誤完成編譯。

**Monorepo 驗收：**
- 根目錄 `npm install` 無錯誤
- 兩個 workspace 正確識別

---

## 完成後的目錄結構

```
{根目錄}/
├── package.json              # root workspace
├── .gitignore
├── generated/
│   └── .gitkeep
├── {後端目錄名稱}/           # NestJS + Fastify（CLI 生成）
│   ├── package.json
│   ├── src/
│   │   ├── main.ts           # Fastify adapter 已配置
│   │   ├── app.module.ts
│   │   └── common/
│   │       ├── interceptors/
│   │       └── filters/
│   └── ...
└── {前端目錄名稱}/           # Vue 3 + Vite + Tailwind（CLI 生成）
    ├── package.json
    ├── tailwind.config.js    # Tailwind CLI 生成
    ├── vite.config.ts
    └── src/
        ├── main.ts
        └── style.css         # Tailwind directives 已加入
```

## 注意事項

- **CLI 順序不可顛倒**：一定要先執行 NestJS CLI 和 Vite CLI 建立子目錄，再設定 root `package.json`，最後才執行 `npm install`
- **後續模組生成**：在 `{後端目錄名稱}/` 內使用 `nest generate module|controller|service` 生成 NestJS 模組
- **後續套件安裝**：從根目錄使用 `npm install {pkg} --workspace={子目錄名稱}` 安裝套件

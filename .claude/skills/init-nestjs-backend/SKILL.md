---
name: init-nestjs-backend
description: 使用 NestJS 官方 CLI 初始化後端專案，配置 Fastify adapter、全域 ValidationPipe、Response Wrapper Interceptor、HttpException Filter。所有檔案骨架一律由 CLI 生成，僅 main.ts 需手動修改。
---

# Init NestJS Backend

使用官方 CLI 初始化一個 NestJS 後端專案，並完成標準化配置。

## 執行前確認

在開始前，先詢問使用者以下資訊（若已在對話中提供則跳過）：

1. **專案目錄名稱**：後端資料夾名稱（預設：`backend`）
2. **API base path**：全域 prefix（預設：`api/v1`）
3. **Port**：監聽埠號（預設：`3000`）
4. **是否在 monorepo 內**：若是，CLI 要在 monorepo root 執行

## 執行步驟

### Step 1：CLI 建立專案

在正確的目錄下執行：

```bash
npx @nestjs/cli new {專案目錄名稱} --package-manager npm --skip-git
```

CLI 會自動生成完整專案結構，包含 `src/main.ts`、`src/app.module.ts`、`tsconfig.json` 等。

> 絕對不要手動建立任何 boilerplate 檔案，一律由 CLI 生成。

### Step 2：安裝 Fastify Adapter

```bash
cd {專案目錄名稱}
npm install @nestjs/platform-fastify
```

### Step 3：CLI 生成 Interceptor 骨架

使用 `nest generate` 建立 Response Wrapper Interceptor：

```bash
nest g interceptor common/interceptors/response-wrapper --no-spec --flat
```

CLI 會生成 `src/common/interceptors/response-wrapper.interceptor.ts`，再將邏輯填入：

```typescript
import { Injectable, NestInterceptor, ExecutionContext, CallHandler } from '@nestjs/common';
import { Observable } from 'rxjs';
import { map } from 'rxjs/operators';

@Injectable()
export class ResponseWrapperInterceptor implements NestInterceptor {
  intercept(context: ExecutionContext, next: CallHandler): Observable<any> {
    return next.handle().pipe(
      map((data) => ({
        data,
        meta: {},
        error: null,
      })),
    );
  }
}
```

### Step 4：CLI 生成 Filter 骨架

使用 `nest generate` 建立 HttpException Filter：

```bash
nest g filter common/filters/http-exception --no-spec --flat
```

CLI 會生成 `src/common/filters/http-exception.filter.ts`，再將邏輯填入：

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

### Step 5：修改 main.ts

這是**唯一需要手動修改**的檔案，因為 Fastify adapter 切換沒有對應 CLI 指令：

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

### Step 6：驗收

```bash
npm run start:dev
```

確認：
- 服務啟動無 TypeScript 編譯錯誤
- `GET http://localhost:{port}/{api_base_path}` 回傳 `{ data, meta, error }` 格式

## 注意事項

- 所有新增的 Module / Controller / Service / Interceptor / Filter / Guard / Pipe 一律使用 `nest generate` CLI 生成骨架
- 唯一合理的手動修改是 `main.ts`（Fastify adapter 設定、全域註冊）
- 若專案在 monorepo 內，後續安裝套件應從根目錄使用 `npm install {pkg} --workspace={專案目錄名稱}`

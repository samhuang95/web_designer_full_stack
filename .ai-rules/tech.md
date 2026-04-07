---
title: Technology Stack
description: "Specifies the languages, frameworks, libraries, tools, and architectural patterns used in the full-stack website generation system."
inclusion: always
---

# Technology Stack

## Language

- **Primary Language:** Node.js >= 20（使用 **NVM** 管理版本）
  - Used for the backend server, API routing, database layer, and generation orchestration logic.
- **Frontend Languages:** TypeScript, HTML5, CSS3
  - All generated website frontends and the admin panel frontend use a compiled build pipeline (see below).

## Backend Framework

**Decided: NestJS**

- Decorator-based, TypeScript-first，內建 Module / Controller / Service / DI 架構
- 底層使用 Fastify adapter（效能優化）：`@nestjs/platform-fastify`
- 分層架構天然對應本專案的分類器、生成器、儲存層、Admin CRUD 等模組邊界
- 未來 AWS ECS Fargate 容器化部署無障礙

**核心 NestJS 模組規劃：**
| Module | 職責 |
|---|---|
| `ClassifierModule` | 自然語言 → 網站類型識別 |
| `GeneratorModule` | 模板渲染與專案生成 |
| `StorageModule` | Drizzle ORM 資料存取層 |
| `AdminModule` | 後台 CRUD 路由 |
| `SettingsModule` | 資料庫連線切換、LLM Token 管理 |

### Database ORM / Query Builder

**Decided: Drizzle ORM** — DB First approach.

| Concern | Drizzle 的表現 |
|---|---|
| DB First 反向工程 | `drizzle-kit introspect` 從現有 DB 生成 TypeScript schema |
| 動態建表（生成階段）| 可直接執行 raw SQL，不強制 schema 定義 |
| SQLite → PostgreSQL 切換 | 同一套 API，只換 driver（`better-sqlite3` → `postgres.js`）|
| TypeScript 型別安全 | schema 定義即型別，無需額外 generate 步驟 |
| 輕量 | 無 CLI daemon，無 binary query engine（Prisma 的痛點）|

**Driver 配置：**
- 開發 / 生成階段（SQLite）：`better-sqlite3`
- 生產（AWS RDS）：`postgres.js`

**Workflow：**
```
設計 SQLite Schema (SQL DDL)
        ↓
drizzle-kit introspect   ← 從現有 DB 反向生成 TypeScript schema
        ↓
TypeScript 型別 + Drizzle 查詢 API 自動產生
```

## Frontend (Generated Website Templates)

All generated website frontends use a compiled SPA stack:

- **Framework:** Vue 3 (Composition API + `<script setup>`)
- **Build Tool:** Vite
- **Language:** TypeScript
- **Styling:** Tailwind CSS (PostCSS plugin, compiled via Vite — not CDN play)
- Each generated `frontend/` directory is a standalone Vite project with its own `package.json`, `vite.config.ts`, and `tailwind.config.ts`.
- Running `npm run build` inside `frontend/` produces a static `dist/` suitable for deployment to S3 + CloudFront.

## Frontend (Admin Panel)

The admin panel frontend follows the same stack as generated websites:

- **Framework:** Vue 3 + TypeScript + Vite + Tailwind CSS
- The admin panel is a separate Vite project, served either as a standalone SPA or bundled as part of the backend server's static asset serving.
- This replaces the previous HTMX + Alpine.js + Jinja2 server-rendered approach.

## Database Layer

### Default Database
- **SQLite** as the default, zero-configuration local development database.
- Access via **Drizzle ORM** + `better-sqlite3` driver.
- Database file is stored at `database/site.db` within each generated project output directory.

### Switchable Database Backends
- Supported remote backends: **PostgreSQL** (primary target for production on AWS RDS/Aurora), MySQL.
- Local file storage fallback: JSON export/import for non-technical users.
- Switching is handled via environment variable (`DATABASE_URL`) and ORM datasource configuration — no code changes required.

### Migrations
- Managed by `drizzle-kit generate` + `drizzle-kit migrate`.
- DB First 流程：先修改 SQL Schema → `drizzle-kit introspect` 更新 TypeScript schema → `drizzle-kit migrate` 執行遷移。

## Website Type Classification

### Current Approach (Initial Version)
- **Pure rule-based keyword matching** — no AI API call.
- A keyword-to-type mapping table maps words from the user's prompt (e.g., "shop", "store", "buy") to a website type (e.g., `ecommerce`).
- Deterministic, zero external dependency, zero latency.

### Future Approach (Planned)
- User supplies their own LLM API token (Claude API or OpenAI API) via the admin panel settings page.
- When a valid token is stored, the system switches from rule-based to LLM-assisted classification.
- The admin panel settings page includes:
  - Token input field (write-only display after save)
  - Classification mode toggle: **Rule-based** vs **LLM-assisted**
  - Token is stored in the server's `.env` file or a secrets store — never committed to version control.
- The LLM call is a single prompt: the user's description is sent to the API, and the response is parsed for a website type label.

## AI Agent Integration

- The project is designed to be driven by a Claude Code AI agent following the four-role model described in `README.md`:
  1. System Planner: interprets user intent and selects the website type.
  2. System Architect: maps the type to the correct template and schema.
  3. Development Engineer: executes the generation tasks.
  4. Test Engineer: validates the output.
- Voice notifications follow the rules in `CLAUDE.md` using the scripts in `notifications/`.

## CLI-First Development Principle

> **核心原則：所有前端、後端、部署框架的初始化與設定，一律優先使用官方 CLI 工具完成，確保專案結構標準化、可重現。**

| 工具 | CLI 指令 |
|---|---|
| NestJS 專案初始化 | `npx @nestjs/cli new project-name` |
| NestJS 模組 / 控制器 / 服務生成 | `nest generate module \| controller \| service` |
| Vue 3 前台初始化 | `npm create vite@latest -- --template vue-ts` |
| Tailwind CSS 設定 | `npx tailwindcss init` |
| Drizzle ORM 設定 | `npx drizzle-kit init` |
| Drizzle 反向工程 | `npx drizzle-kit introspect` |
| Drizzle 遷移生成 | `npx drizzle-kit generate` |
| Drizzle 遷移執行 | `npx drizzle-kit migrate` |

**規則：**
1. 禁止手動建立框架的 boilerplate 檔案（如 `main.ts`、`app.module.ts`），一律由 CLI 生成
2. 新增 NestJS 模組時必須使用 `nest g module <name>`，確保自動註冊到 `AppModule`
3. 生成的 CLI 結構不得手動重組，保持框架預設目錄慣例
4. 所有 CLI 指令需記錄在 `README.md` 的 Getting Started 區段，確保可重現

## Project Configuration & Tooling

| Concern | Tool |
|---|---|
| Package manager | `npm` (or `pnpm` — decision pending) |
| Monorepo / workspace | npm workspaces or a flat multi-package layout |
| Environment variables | `dotenv` + `.env` file (never committed) |
| Testing | `vitest` (unit), `supertest` (API integration) |
| Linting | `eslint` with TypeScript rules |
| Formatting | `prettier` |
| Type checking | `tsc --noEmit` (strict mode) |

## Development Commands

```bash
# Install all dependencies
npm install

# Start the backend development server (adjust once framework is chosen)
npm run dev

# Build all frontends (generated sites and admin panel)
npm run build

# Run tests
npm run test

# Lint and format
npm run lint && npm run format

# Type check
npm run typecheck
```

> Exact script names will be finalized once the framework and monorepo layout are decided.

## Architecture Pattern

- **Monorepo layout:** Source templates, backend logic, and admin panel frontend live in the same repository.
- **Generated output** is placed inside a `generated/` directory, one subdirectory per generation session (named `{slug}_{timestamp}`), with three explicit sub-directories: `frontend/`, `backend/`, and `database/`.
- **Generated `frontend/`** is a self-contained Vue 3 + Vite project requiring a build step before serving.
- **Admin panel** is served from the same Node.js application, either at `/admin` or as a separate Vite dev server during development.
- **Storage adapter pattern:** All database access goes through a common interface with implementations for SQLite (local) and PostgreSQL (production). This enables runtime backend switching without code changes.

## Deployment Architecture (Future Planning)

> This section describes the target cloud deployment. Initial development is local-first. Cloud deployment is a future milestone.

### Target Platform: AWS

All services are chosen to support **horizontal scaling** of the Node.js backend.

#### Compute (Backend) — Options

| Option | Characteristic | Recommendation |
|---|---|---|
| **ECS Fargate** | Containerized, auto-scaling, no server management. | **Recommended** — best balance of control and operational simplicity for a Node.js API. |
| **Lambda + API Gateway** | Serverless, pay-per-request, cold start latency. | Consider if traffic is very spiky and cost optimization is critical. |
| **Elastic Beanstalk** | Managed PaaS, simple deployment but less flexible scaling. | Acceptable for early production; migrate to ECS Fargate as load grows. |
| **EC2 Auto Scaling Group** | Full control, more operational overhead. | Only if custom OS/hardware config is required. |

#### Frontend Static Assets
- **S3 + CloudFront:** Generated `frontend/dist/` and admin panel `dist/` are deployed to S3 and served via CloudFront CDN.
- CloudFront handles HTTPS termination and global edge caching.

#### Database
| Option | Characteristic |
|---|---|
| **RDS PostgreSQL** | Managed, Multi-AZ for HA, familiar SQL. Recommended starting point. |
| **Aurora Serverless v2** | Auto-scales read/write capacity, higher cost at steady load. |

#### Other Services
- **ECR:** Container registry for Docker images (if using ECS Fargate).
- **Secrets Manager / Parameter Store:** Stores `DATABASE_URL`, LLM API tokens, and other secrets — never in code or `.env` in production.
- **ALB (Application Load Balancer):** Routes traffic across ECS tasks for horizontal scaling.

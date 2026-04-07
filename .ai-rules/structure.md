---
title: Project Structure
description: "Defines the directory layout, module organization, naming conventions, and placement rules for all new files in the project."
inclusion: always
---

# Project Structure

## Top-Level Directory Layout

```
web_designer_full_stack/
├── .ai-rules/               # AI agent steering files (product.md, tech.md, structure.md)
├── .claude/                 # Claude Code local settings (settings.local.json)
├── notifications/           # Voice notification shell scripts for the AI agent
│   ├── decision_notify.sh
│   ├── task_complete_notify.sh
│   └── speak_message.sh
├── src/                     # Node.js backend application source
│   ├── main.ts              # Application entry point, server bootstrap
│   ├── app.module.ts        # Root module (NestJS) or app factory (Express/Fastify)
│   ├── classifier/          # Natural language -> website type classification
│   │   └── classifier.ts    # Rule-based keyword matching (current); LLM adapter (future)
│   ├── generator/           # Orchestrates the full generation pipeline
│   │   └── generator.ts
│   ├── templates/           # Template registry and website type definitions
│   │   ├── registry.ts      # Maps website types to template dirs and schemas
│   │   └── schemas/         # TypeScript interfaces / Zod schemas per website type
│   │       ├── ecommerce.ts
│   │       ├── portfolio.ts
│   │       ├── landing.ts
│   │       ├── blog.ts
│   │       └── business.ts
│   ├── storage/             # Storage adapter abstraction
│   │   ├── storage.interface.ts   # StorageAdapter interface
│   │   ├── sqlite.adapter.ts      # SQLite implementation (default)
│   │   └── postgres.adapter.ts    # PostgreSQL implementation (production)
│   ├── routers/             # HTTP route handlers (thin layer — no business logic)
│   │   ├── generation.router.ts   # POST /api/generate
│   │   ├── admin.router.ts        # /admin/* CRUD routes
│   │   └── settings.router.ts     # /api/settings/* — DB switching, LLM token config
│   └── config/              # Environment config loading and validation
│       └── config.ts
├── admin-panel/             # Admin panel frontend (Vue 3 + Vite + Tailwind + TypeScript)
│   ├── src/
│   │   ├── main.ts
│   │   ├── App.vue
│   │   ├── components/      # Shared UI components
│   │   ├── views/           # Page-level Vue components (list, form, settings)
│   │   └── api/             # API client functions (calls backend REST endpoints)
│   ├── index.html
│   ├── vite.config.ts
│   ├── tailwind.config.ts
│   └── package.json
├── website_templates/       # Source templates for generated websites (read-only at runtime)
│   ├── ecommerce/           # Vue 3 + Vite project scaffold for ecommerce sites
│   ├── portfolio/           # Vue 3 + Vite project scaffold for portfolio sites
│   ├── landing/
│   ├── blog/
│   └── business/
├── generated/               # Output directory for generated projects (gitignored)
│   └── {slug}_{timestamp}/  # One subdirectory per generation session
│       ├── frontend/        # Complete Vue 3 + Vite project (copied + hydrated from website_templates/)
│       │   ├── src/
│       │   ├── index.html
│       │   ├── vite.config.ts
│       │   ├── tailwind.config.ts
│       │   └── package.json
│       ├── backend/         # Node.js backend project for this generated site
│       │   ├── src/
│       │   ├── package.json
│       │   └── .env.example
│       └── database/        # Database files and configuration
│           └── site.db      # Default SQLite database for this generated site
├── tests/                   # All tests (mirrors src/ layout)
│   ├── unit/
│   │   ├── classifier.test.ts
│   │   ├── generator.test.ts
│   │   └── storage.test.ts
│   └── integration/
│       └── api.test.ts
├── data/                    # Shared seed data and fixtures
│   └── seeds/               # JSON seed files per website type
│       ├── ecommerce.json
│       └── portfolio.json
├── .env.example             # Example environment variable file
├── .gitignore
├── package.json             # Root package.json (workspaces or single-package)
├── tsconfig.json            # Root TypeScript config
├── CLAUDE.md                # AI agent rules (voice notifications, mode switching)
└── README.md                # Human-readable project overview
```

## Generated Output Directory — Detail

Each generation session produces exactly this structure under `generated/{slug}_{timestamp}/`:

```
generated/
└── {slug}_{timestamp}/          # e.g., my_shop_20260407_143000/
    ├── frontend/                # Standalone Vue 3 + Vite project
    │   ├── src/
    │   │   ├── main.ts
    │   │   ├── App.vue
    │   │   ├── components/
    │   │   └── views/
    │   ├── index.html
    │   ├── vite.config.ts
    │   ├── tailwind.config.ts
    │   └── package.json         # Has its own deps; run `npm install` then `npm run build`
    ├── backend/                 # Standalone Node.js backend project
    │   ├── src/
    │   │   └── main.ts
    │   ├── package.json
    │   ├── tsconfig.json
    │   └── .env.example         # DATABASE_URL and other runtime config
    └── database/                # Database files and schema
        ├── site.db              # SQLite file (default, zero-config)
        └── schema.sql           # Raw SQL schema for reference / migration to other DBs
```

Key rules for generated output:
- The three sub-directories `frontend/`, `backend/`, and `database/` are always created, even if empty.
- `frontend/` is a complete, self-contained Vite project. A developer can `cd frontend && npm install && npm run dev` to run it.
- `backend/` is a complete, self-contained Node.js project. A developer can `cd backend && npm install && npm run dev` to run it.
- `database/site.db` is pre-seeded with sample data matching the website type's schema.
- The `generated/` directory is listed in `.gitignore`. Generated site files must never be committed.

## Naming Conventions

| Scope | Convention | Example |
|---|---|---|
| TypeScript source files | `kebab-case.ts` | `sqlite.adapter.ts`, `classifier.ts` |
| TypeScript classes | `PascalCase` | `StorageAdapter`, `EcommerceSchema` |
| TypeScript functions and variables | `camelCase` | `getDbSession()`, `websiteType` |
| Vue single-file components | `PascalCase.vue` | `ProductCard.vue`, `AdminForm.vue` |
| Vue component directories | `kebab-case` | `components/product-card/` |
| Website template directories | `snake_case` matching the type name | `ecommerce/`, `portfolio/` |
| Generated project directories | `{slug}_{YYYYMMDD_HHMMSS}` | `my_shop_20260407_143000/` |
| Environment variables | `SCREAMING_SNAKE_CASE` | `DATABASE_URL`, `SECRET_KEY`, `LLM_API_TOKEN` |
| API route paths | `kebab-case` segments | `/api/generate`, `/admin/list-items` |
| Test files | Mirror source name with `.test.ts` suffix | `classifier.test.ts` |

## Module Placement Rules

1. **New website type templates** go in `website_templates/{type_name}/` as a Vue 3 + Vite project scaffold, and must have a corresponding TypeScript schema in `src/templates/schemas/{type_name}.ts` and an entry in `src/templates/registry.ts`.

2. **New storage backends** must implement the `StorageAdapter` interface defined in `src/storage/storage.interface.ts`. The implementation file goes in `src/storage/` and must be registered in the adapter factory.

3. **New HTTP route handlers** go in `src/routers/` as a separate module and must be registered in the main app module or entry point. Route handlers must not contain business logic — they delegate to `src/classifier/`, `src/generator/`, or `src/storage/`.

4. **All business and domain logic** lives in `src/classifier/`, `src/generator/`, and `src/storage/`. Route handlers in `src/routers/` handle only HTTP concerns (parsing, validation, response shaping).

5. **Admin panel UI components** go in `admin-panel/src/components/` (shared) or `admin-panel/src/views/` (page-level). API calls from the admin panel go in `admin-panel/src/api/`.

6. **Tests** mirror the source layout: a test for `src/classifier/classifier.ts` goes in `tests/unit/classifier.test.ts`.

7. **Generated output** is always written to `generated/` and this directory is gitignored. Never commit generated site files.

8. **AI agent steering files** go in `.ai-rules/` only. Do not place steering documentation in the root or in `src/`.

9. **LLM API tokens and secrets** are stored in `.env` files only. The `.env` file is gitignored. `.env.example` documents required variables without values.

## Data Flow Summary

```
User Prompt (text)
      |
      v
src/routers/generation.router.ts (POST /api/generate)
      |
      v
src/classifier/classifier.ts  --> identifies website_type (e.g., "ecommerce")
                                   [current: keyword matching; future: LLM API call]
      |
      v
src/templates/registry.ts     --> looks up template dir + schema for website_type
      |
      v
src/generator/generator.ts    --> copies website_templates/{type}/ to generated/{slug}_{ts}/frontend/
                                   hydrates Vue component data, writes backend scaffold,
                                   writes generated/{slug}_{ts}/backend/
      |
      v
src/storage/sqlite.adapter.ts --> initializes database/site.db and seeds tables
                                   writes generated/{slug}_{ts}/database/site.db
      |
      v
admin-panel (Vue 3 SPA)       --> serves CRUD admin panel for the generated site's data
      |
      v
src/routers/settings.router.ts --> allows switching storage backend and configuring LLM token
```

## Development Milestones

### Milestone 1 — Foundation (Priority: High)
- Project scaffold: `package.json`, `tsconfig.json`, backend entry point in `src/main.ts`
- Framework decision: choose and install NestJS, Fastify, or Express
- ORM decision: choose and configure Prisma or Drizzle with SQLite datasource
- `src/storage/storage.interface.ts` and `src/storage/sqlite.adapter.ts`
- `src/classifier/classifier.ts` (rule-based keyword matching — no LLM API required)
- Basic `POST /api/generate` endpoint that accepts a prompt and returns a session ID

### Milestone 2 — Template Engine (Priority: High)
- `src/templates/registry.ts` with at least two website types: `ecommerce` and `portfolio`
- Vue 3 + Vite project scaffolds for both types in `website_templates/`
- `src/generator/generator.ts` that copies, hydrates, and writes output to `generated/{slug}_{ts}/`
- Confirm `generated/{slug}_{ts}/frontend/` can be built with `npm run build` after generation

### Milestone 3 — Admin Panel (Priority: High)
- `admin-panel/` Vue 3 + Vite project with base layout, list view, and form view
- Dynamic CRUD API routes in `src/routers/admin.router.ts` driven by the active website type's schema
- Integration with SQLite storage adapter

### Milestone 4 — Settings & Storage Switching (Priority: Medium)
- Settings API in `src/routers/settings.router.ts`
- Settings UI in `admin-panel/src/views/Settings.vue`
- `src/storage/postgres.adapter.ts` (connection string input, ORM migration trigger)
- LLM API token input field in settings UI; token stored in `.env`, never in DB

### Milestone 5 — LLM Classification & Additional Templates (Priority: Medium)
- LLM-assisted classifier behind a feature flag (active when `LLM_API_TOKEN` is set and mode is toggled)
- Classification mode toggle in settings UI (Rule-based vs LLM-assisted)
- Add `landing`, `blog`, and `business` website type templates
- Seed data JSON files in `data/seeds/`
- End-to-end integration tests in `tests/integration/`
- Voice notification hooks for generation start, completion, and errors

### Milestone 6 — AWS Deployment (Priority: Low / Future)
- Dockerize backend (`src/`) and admin panel (`admin-panel/`)
- CI/CD pipeline: build frontend `dist/`, push Docker image to ECR, deploy to ECS Fargate
- Terraform or CDK scripts for: ALB, ECS Fargate service, RDS PostgreSQL, S3 + CloudFront, Secrets Manager
- Switch `DATABASE_URL` from SQLite to RDS PostgreSQL in production environment

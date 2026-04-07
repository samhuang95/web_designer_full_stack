---
title: Product Vision
description: "Defines the project's core purpose, target users, and main features for the conversational full-stack website generation system."
inclusion: always
---

# Product Vision: Web Designer Full-Stack Generation System

## Project Overview

This is a conversation-driven, full-stack website auto-generation platform. A user describes the type of website they want in natural language, and the system automatically scaffolds and delivers a complete, runnable web application — including a public-facing frontend, an admin backend panel, and a pre-configured SQLite database.

The system eliminates the need for manual project setup, boilerplate coding, or database configuration for common website types.

## Target Users

- Developers and freelancers who need to rapidly prototype or deliver client websites.
- Non-technical users who want a working website without writing code.
- Small business owners who need a website with a manageable admin panel.
- AI agent workflows that orchestrate website generation as a downstream task.

## Core Problem Solved

Setting up a full-stack web project — frontend, backend, admin UI, and database — is repetitive and time-consuming. This system reduces that process to a single natural-language prompt, producing a fully wired, runnable application in one step.

## Key Features

### 1. Conversational Website Generation
- User inputs a natural-language description (e.g., "an e-commerce store for handmade jewelry" or "a personal portfolio for a photographer").
- The system identifies the website type and maps it to the best-matching template category.
- Supported initial website types: e-commerce, personal portfolio/resume, product landing page, blog, and company/business site.

### 2. Frontend Template Engine
- Each website type has a corresponding Vue 3 + Vite + Tailwind CSS + TypeScript project scaffold.
- Generated frontends are compiled SPAs — running `npm run build` inside `frontend/` produces deployable static assets.
- Templates are data-driven: all content is fetched from the backend API, not hardcoded.

### 3. Auto-Generated Backend Admin Panel
- Every generated project includes a backend admin panel (Vue 3 + Vite SPA) with full CRUD operations for all data entities.
- The admin panel is dynamically configured based on the website type's data schema.
- Admin panel provides: list views, create/edit forms, delete confirmations, and basic search/filter.
- The admin panel settings page includes: database connection switching, and LLM API token configuration (see Feature 5).

### 4. Database Layer with Switchable Storage
- SQLite is the default database for zero-configuration local development.
- The admin panel exposes a database connection settings page where the user can switch to:
  - Local file storage (JSON or CSV export/import)
  - A remote database connection (e.g., PostgreSQL, MySQL) via a connection string
- The system migrates or seeds data when the storage backend is switched.

### 5. Website Type Classification

#### Current Approach (Initial Version)
- **Pure rule-based keyword matching** — no external AI API call, no external dependency.
- A keyword-to-type mapping table maps words from the user's prompt (e.g., "shop", "store", "buy") to a website type (e.g., `ecommerce`).
- Deterministic, zero latency, works fully offline.

#### Future Approach (Planned)
- Users supply their own LLM API token (Claude API or OpenAI API) via the admin panel settings page.
- When a valid token is stored, the system offers an **LLM-assisted classification mode** that sends the user's description to the LLM for more accurate intent recognition.
- The admin panel settings page provides:
  - A token input field (write-only display after save)
  - A classification mode toggle: **Rule-based** vs **LLM-assisted**
  - Tokens are stored server-side in a `.env`-style secrets store — never committed to version control.

### 6. AI Agent-Driven Generation
- The system uses the user's natural-language input to pre-fill site name, color themes, and initial seed data where applicable.
- The AI agent driving generation follows the multi-role model defined in this project: system planner, system architect, development engineer, and test engineer.

## Non-Goals (Out of Scope for Initial Version)
- Real-time collaborative editing of generated sites.
- Cloud deployment automation (generation is local-first; AWS deployment is a future milestone, not an initial requirement).
- Support for custom code injection by non-technical users.
- Multi-language i18n support in generated templates (English and Traditional Chinese only at launch).
- Bundling or hosting an LLM model — only API-based calls to user-supplied token endpoints are supported.

## Success Criteria
- A user can describe a website type and receive a fully runnable full-stack application within a single generation session.
- The admin panel requires no additional configuration to perform CRUD operations on the generated data model.
- Switching from SQLite to a remote database connection does not require code changes — only UI-level configuration.

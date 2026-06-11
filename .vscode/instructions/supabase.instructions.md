---
applyTo: "**"
description: "Use when doing ANY task involving Supabase. Triggers: Supabase products (Database, Auth, Edge Functions, Realtime, Storage, Vectors, Cron, Queues); client libraries and SSR integrations (supabase-js, @supabase/ssr) in Next.js, React, SvelteKit, Astro, Remix; auth issues (login, logout, sessions, JWT, cookies, getSession, getUser, getClaims, RLS); Supabase CLI or MCP server; schema changes, migrations, security audits, Postgres extensions (pg_graphql, pg_cron, pg_vector)."
---

# Supabase

## Core Principles

**1. Supabase changes frequently — verify against changelog and current docs before implementing.**
Do not rely on training data for Supabase features. Function signatures, config.toml settings, and API conventions change between versions.

First, fetch `https://supabase.com/changelog.md` (a lightweight summary index — not a heavy pull), scan for `breaking-change` tags relevant to your task, and follow the linked page for any that apply. Then look up the relevant topic using the documentation access methods below.

**2. Verify your work.**
After implementing any fix, run a test query to confirm the change works. A fix without verification is incomplete.

**3. Recover from errors, don't loop.**
If an approach fails after 2-3 attempts, stop and reconsider. Try a different method, check documentation, inspect the error more carefully, and review relevant logs when available.

**4. Exposing tables to the Data API:**
Depending on the user's Data API settings, newly created tables may not be automatically exposed via the Data (REST) API. If this is the case, `anon` and `authenticated` roles will need to be explicitly granted access.

> Note that this is separate from RLS, which controls which _rows_ are visible once a table is accessible, not whether the table is accessible at all.

When a user reports a SQL-created table is unexpectedly inaccessible, check their Data API settings and whether the roles have been granted access via explicit `GRANT` SQL. When granting public (`anon`/`authenticated`) access, always enable RLS too.

**5. RLS in exposed schemas.**
Enable RLS on every table in any exposed schema, which includes `public` by default. This is critical in Supabase because tables in exposed schemas can be reachable through the Data API when the `anon`/`authenticated` roles have access. After enabling RLS, create policies that match the actual access model rather than defaulting every table to the same `auth.uid()` pattern.

**6. Security checklist.**
When working on any Supabase task that touches auth, RLS, views, storage, or user data:

- **Auth and session security**
  - **Never use `user_metadata` claims in JWT-based authorization decisions.** `raw_user_meta_data` is user-editable and can appear in `auth.jwt()`, so it is unsafe for RLS policies or any other authorization logic. Store authorization data in `raw_app_meta_data` / `app_metadata` instead.
  - **Deleting a user does not invalidate existing access tokens.** Sign out or revoke sessions first, keep JWT expiry short for sensitive apps.
  - **If you use `app_metadata` or `auth.jwt()` for authorization, remember JWT claims are not always fresh until the user's token is refreshed.**

- **API key and client exposure**
  - **Never expose the `service_role` or secret key in public clients.** Prefer publishable keys for frontend code. In Next.js, any `NEXT_PUBLIC_` env var is sent to the browser.

- **RLS, views, and privileged database code**
  - **Views bypass RLS by default.** In Postgres 15+, use `CREATE VIEW ... WITH (security_invoker = true)`.
  - **UPDATE requires a SELECT policy.** Without a SELECT policy, updates silently return 0 rows.
  - **Do not put `security definer` functions in an exposed schema.**

- **Storage access control**
  - **Storage upsert requires INSERT + SELECT + UPDATE.** Granting only INSERT allows new uploads but file replacement silently fails.

## Supabase MCP Server

For setup instructions, server URL, and configuration, see the [MCP setup guide](https://supabase.com/docs/guides/getting-started/mcp).

**Troubleshooting connection issues:**

1. **Check if the server is reachable:**
   `curl -so /dev/null -w "%{http_code}" https://mcp.supabase.com/mcp`
   A `401` is expected (no token) and means the server is up.

2. **Check `.vscode/mcp.json` configuration:**
   Verify the project has a valid `.vscode/mcp.json` with the correct server URL pointing to `https://mcp.supabase.com/mcp?project_ref=<ref>`.

3. **Authenticate the MCP server:**
   The Supabase MCP server uses OAuth 2.1 — tell the user to trigger the auth flow in their agent, complete it in the browser, and reload the session.

## Supabase CLI

Always discover commands via `--help` — never guess.

```bash
supabase --help
supabase <group> --help
supabase <group> <command> --help
```

**Known gotchas:**
- `supabase db query` requires CLI v2.79.0+
- `supabase db advisors` requires CLI v2.81.3+
- Always create migration files with `supabase migration new <name>` first.

## Making and Committing Schema Changes

**To make schema changes, use `execute_sql` (MCP) or `supabase db query` (CLI).**

Do NOT use `apply_migration` to change a local database schema during iteration — it writes a migration history entry on every call.

**When ready to commit:**
1. Run advisors → `supabase db advisors`
2. Review the Security Checklist above
3. Generate the migration → `supabase db pull <descriptive-name> --local --yes`
4. Verify → `supabase migration list --local`

## Supabase Documentation

Before implementing any Supabase feature, find the relevant documentation:

1. **MCP `search_docs` tool** (preferred)
2. **Fetch docs pages as markdown** — append `.md` to any docs URL path
3. **Web search** for Supabase-specific topics

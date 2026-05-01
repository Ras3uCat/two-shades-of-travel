# FEATURE: MCP Server Configuration
**Mode:** FLOW
**Priority:** P1
**Status:** BACKLOG

## Overview
Configure Supabase and GitHub MCP servers in `.claude/settings.local.json`. Currently the file only contains legacy `permissions`. Adding MCP gives Claude direct query access to live DB schema, RLS policies, Edge Function logs, and GitHub issues — eliminating the need to read migration files to understand current schema state.

## Acceptance Criteria
- [ ] Supabase MCP configured in `settings.local.json` with project URL + service role key
- [ ] GitHub MCP configured with PAT scoped to this repo
- [ ] `/health` slash command reports both MCP servers as active (not placeholder credentials)
- [ ] Claude can answer "what columns does the bookings table have?" without reading any files

## Scope
- `.claude/settings.local.json` — add `mcpServers` block

## Notes
- Reference: `dev_files/.claude/settings.local.json` has the mcpServers structure
- Service role key goes here (settings.local.json is .gitignored)
- Supabase MCP package: `@supabase/mcp-server-supabase`
- GitHub MCP package: `@modelcontextprotocol/server-github`

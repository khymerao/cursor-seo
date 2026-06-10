---
name: cursor-seo-router
description: >
  Entry point for all SEO work in Cursor. Replaces upstream claude-seo /seo
  slash commands. Use when the user asks for an SEO audit, page analysis,
  technical SEO, E-E-A-T content review, schema markup, GEO/AI-search
  optimization, sitemaps, image SEO, local SEO, maps intelligence, keyword
  clustering, SXO, drift monitoring, e-commerce SEO, hreflang, Google API data
  (GSC, PageSpeed, CrUX, GA4), backlinks, or live DataForSEO data.
license: MIT
metadata:
  version: "2.0.0-cursor.1"
  upstream: claude-seo v2.0.0 (AgriciDaniel)
---

# Cursor SEO Router

Single entry point for the cursor-seo plugin (port of claude-seo). Upstream
users typed `/seo <command>`; in Cursor, parse the user's goal and dispatch to
the right skill below. All paths are relative to this plugin's root
(`~/.cursor/plugins/local/cursor-seo`, or `$CURSOR_PLUGIN_ROOT` in hooks).

## Command map

| User intent (upstream command) | Dispatch |
|---|---|
| Full site audit (`/seo audit <url>`) | `skills/seo/SKILL.md` orchestrator + inline agents (see below) |
| Single page deep-dive (`/seo page`) | `skills/seo-page/SKILL.md` |
| Technical SEO (`/seo technical`) | `skills/seo-technical/SKILL.md` + `agents/seo-technical.md` |
| Content / E-E-A-T (`/seo content`) | `skills/seo-content/SKILL.md` |
| Content brief (`/seo content-brief`) | `skills/seo-content-brief/SKILL.md` |
| Schema markup (`/seo schema`) | `skills/seo-schema/SKILL.md` + `scripts/schema_generate.py` |
| GEO / AI search (`/seo geo`) | `skills/seo-geo/SKILL.md` |
| Sitemap (`/seo sitemap`) | `skills/seo-sitemap/SKILL.md` |
| Images (`/seo images`) | `skills/seo-images/SKILL.md` |
| Strategic plan (`/seo plan <type>`) | `skills/seo-plan/SKILL.md` (assets: saas, local-service, ecommerce, publisher, agency, generic) |
| Programmatic SEO (`/seo programmatic`) | `skills/seo-programmatic/SKILL.md` |
| Competitor pages (`/seo competitor-pages`) | `skills/seo-competitor-pages/SKILL.md` |
| Local SEO (`/seo local`) | `skills/seo-local/SKILL.md` |
| Maps intelligence (`/seo maps`) | `skills/seo-maps/SKILL.md` |
| Hreflang / i18n (`/seo hreflang`) | `skills/seo-hreflang/SKILL.md` |
| Google APIs (`/seo google …`) | `skills/seo-google/SKILL.md` (credentials live in `~/.config/claude-seo/` — keep that path; scripts hardcode it) |
| Backlinks (`/seo backlinks`) | `skills/seo-backlinks/SKILL.md` |
| Keyword clustering (`/seo cluster`) | `skills/seo-cluster/SKILL.md` |
| SXO (`/seo sxo`) | `skills/seo-sxo/SKILL.md` |
| Drift monitoring (`/seo drift baseline|compare|history`) | `skills/seo-drift/SKILL.md` |
| E-commerce (`/seo ecommerce`) | `skills/seo-ecommerce/SKILL.md` |
| FLOW prompts (`/seo flow`) | `skills/seo-flow/SKILL.md` |
| Live data (`/seo dataforseo <cmd>`) | `skills/seo-dataforseo/SKILL.md` → **`user-dataforseo` MCP tools** (see `skills/seo-dataforseo/references/cursor-mcp-mapping.md`) |

Not ported (extensions, install separately if needed): firecrawl, image-gen
(banana), ahrefs, seranking, profound, bing-webmaster, unlighthouse. See
`docs/upstream/MCP-INTEGRATION.md`.

## Inline agent contract (replaces Claude sub-agent dispatch)

Cursor plugins cannot register custom subagents. When a skill or this router
references an agent:

1. Read `agents/seo-<name>.md`.
2. **Ignore frontmatter** keys `model`, `maxTurns`, `tools` — Claude Code
   specific.
3. Execute the body instructions **in the current context, sequentially**.
   Do not spawn parallel subagents.

Full-audit agent order: `seo-technical` → `seo-content` → `seo-schema` →
`seo-geo` → `seo-local` (only if the site has a local/physical footprint) →
synthesis via `skills/seo/references/thinking-framework.md` (10 principles),
then emit the prioritized action plan per the orchestrator's report format.

## Running Python scripts

Always use the plugin venv:

```bash
~/.cursor/plugins/local/cursor-seo/.venv/bin/python \
  ~/.cursor/plugins/local/cursor-seo/scripts/<script>.py [args]
```

If the venv is missing, run `setup/setup.sh` first (add `--with-render` for
SPA rendering via Playwright, `--with-pdf` for PDF/Excel reports). Skills
degrade gracefully without the optional extras: raw-HTML fetch instead of
rendered, markdown report instead of PDF.

## Superpowers boundaries

- SEO **deliverable** (audit, report, schema, keywords, briefs): use this
  router directly — no brainstorming gate.
- **Writing code** based on SEO findings (theme/plugin changes, automations):
  hand off to Superpowers `brainstorming` → `writing-plans` first.
- Debugging or testing SEO-related code: Superpowers `systematic-debugging`,
  `test-driven-development`.

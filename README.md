# Cursor SEO

SEO toolkit for Cursor: **25 skills** and **18 specialist workflows** for technical SEO,
content quality (E-E-A-T), Schema.org, GEO / AI search, local SEO, keyword clustering,
SXO, drift monitoring, e-commerce, hreflang, Google APIs, backlinks, and live
DataForSEO data.

Based on [claude-seo v2.0.0](https://github.com/AgriciDaniel/claude-seo) (MIT). See
[ATTRIBUTION.md](ATTRIBUTION.md) for upstream credit.

## Install

```bash
git clone https://github.com/khymerao/cursor-seo.git ~/.cursor/plugins/local/cursor-seo
cd ~/.cursor/plugins/local/cursor-seo && ./setup/setup.sh
# optional:
# ./setup/setup.sh --with-render   # Playwright — SPA / JS-heavy pages
# ./setup/setup.sh --with-pdf      # PDF / Excel reports
```

If system `python3` is older than 3.10:

```bash
PYTHON=python3.12 ./setup/setup.sh
```

Reload Cursor (**Cmd+Shift+P → Reload Window**), then verify:

```bash
./setup/validate.sh
```

Details: [docs/install.md](docs/install.md)

## How it works

```
Your request (chat)
       ↓
cursor-seo-router  ←  or a specific seo-* skill
       ↓
Skill workflow (checklists, report format)
       ↓
Specialist agents (inline, sequential)
       ↓
Python scripts + optional MCP (live data)
       ↓
Findings + prioritized action plan
```

| Layer | What it does |
|-------|----------------|
| **Router skill** | Maps your goal to the right workflow |
| **Trigger rule** | Auto-routes when you mention SEO, audit, schema, CWV, backlinks, etc. |
| **Skills** (`seo-*`) | Step-by-step instructions for each task type |
| **Agents** (`agents/seo-*.md`) | Specialist checklists run **inline in the current chat** (one after another) |
| **Scripts** (`scripts/`) | Fetch, render, schema generate/validate, drift, Google APIs |
| **DataForSEO MCP** | Live SERP, keyword volume, backlinks (optional) |

Describe what you want in natural language — no command palette required. Attach
`/cursor-seo-router` or a specific skill when you want explicit routing.

## Quick start

| Goal | Example prompt |
|------|----------------|
| Full site audit | "Run a full SEO audit on https://example.com" |
| One page | "Deep-dive SEO analysis of https://example.com/pricing" |
| Technical check | "Technical SEO check on /login, /checkout, /404 — new pages" |
| Schema | "Validate and generate JSON-LD schema for the product page" |
| GEO / AI search | "Assess AI citability for ChatGPT / AI Overviews" |
| CLS / performance | "CLS audit on all static HTML pages in src/" |
| Keywords (live) | "Keyword research for 'wordpress crm plugin' via DataForSEO" |
| Drift baseline | "Capture SEO baseline for https://example.com" |

Full skill map: [skills/cursor-seo-router/SKILL.md](skills/cursor-seo-router/SKILL.md)

## Usage patterns (from real workflows)

These are the patterns that work best in Cursor day to day.

### 1. Targeted pass on new pages *(most common)*

After shipping a batch of pages, run a **technical SEO pass** on specific URLs or
files — faster and more actionable than a full audit.

**Scope the prompt:** list URLs, file paths, or page names explicitly.

**Typical checks:** unique `<title>` and meta description, single H1, `canonical`,
`robots` (`noindex` on auth / account / checkout), Open Graph, JSON-LD, crawl paths
(no dead `href="#"`), form labels, internal links.

**Output pattern:** score (optional) → fix table by severity → apply edits →
re-verify with grep or `render_page.py`.

```
Technical SEO pass on checkout.html, sign-up.html, 404.html.
Check head tags, robots, H1 count, JSON-LD, and href="#".
```

### 2. Full audit

For launch readiness, quarterly reviews, or new domains. The orchestrator runs
specialists **sequentially**: technical → content → schema → geo → local (if
applicable) → synthesis with health score (0–100) and prioritized fixes
(Critical / High / Medium / Low).

```
Full SEO audit on https://example.com — include schema, GEO, and SXO.
```

### 3. Static HTML / local files *(no deploy required)*

Audits work on local source before anything is live. Point the agent at file paths
or a local preview URL.

| Method | When |
|--------|------|
| **Source inspection** (grep/read) | Default — meta, schema, headings, links; no venv needed |
| **`render_page.py`** | Extract rendered title, robots, canonical, H1 count; needs venv + `--with-render` for SPAs |
| **Raw HTML fetch** | Fallback when Playwright is not installed |

```
Audit all HTML files in ./public for duplicate titles and missing canonicals.
```

### 4. CLS / Core Web Vitals

Attach `/seo-performance` or ask for a CLS audit. Checks layout-shift risks:
web fonts without fallback metrics, JS injection into empty containers, cookie
banners shifting layout, sticky layers, modals without reserved space.

Target: CLS ≤ 0.1. Live CrUX / PageSpeed requires a deployed URL + Google APIs.

```
CLS audit on index.html, catalog.html, search.html — list fixes by severity.
```

### 5. Keyword research → content plan

With **DataForSEO MCP** configured: seed keywords → SERP overlap clusters → page
mapping. Export CSVs into your project for reference.

Without MCP: on-page audits and static analysis still work; live SERP/volume steps
are skipped or use pasted data.

### 6. Drift monitoring

Capture a baseline before a deploy; compare after to catch regressions in title,
meta, canonical, or schema.

```
Capture SEO drift baseline for https://example.com
Compare drift for https://example.com after today's deploy
```

## Invoking skills

| Method | When |
|--------|------|
| Natural language | Default — the trigger rule routes SEO requests automatically |
| Attach skill | `/cursor-seo-router`, `/seo-technical`, `/seo-schema`, `/seo-performance`, … |
| Explicit scope | List URLs, files, or page names in the prompt |

**Deliverable vs implementation:** audits, reports, schema snippets, and content
briefs → run SEO skills directly. **Code changes** in your codebase (theme, app,
CMS templates) → use your project's planning workflow unless you ask for direct edits.

## Python scripts

Always use the plugin venv:

```bash
~/.cursor/plugins/local/cursor-seo/.venv/bin/python \
  ~/.cursor/plugins/local/cursor-seo/scripts/<script>.py [args]
```

Examples:

```bash
cd ~/.cursor/plugins/local/cursor-seo

# Page metadata extraction (Playwright optional)
.venv/bin/python scripts/render_page.py https://example.com --json

# Schema generate / validate
.venv/bin/python scripts/schema_generate.py --url https://example.com
```

If venv is missing: `./setup/setup.sh`. Without `--with-render`: raw HTML fetch
instead of headless browser — most head-tag checks still work.

## Live data (DataForSEO)

Core audits work **offline**. For live SERP, keyword volume, and backlinks API:

→ [docs/mcp-setup.md](docs/mcp-setup.md)  
→ Tool mapping: [skills/seo-dataforseo/references/cursor-mcp-mapping.md](skills/seo-dataforseo/references/cursor-mcp-mapping.md)

## Google APIs (optional)

GSC, PageSpeed, CrUX, GA4 — credentials in `~/.config/claude-seo/`. See
`skills/seo-google/SKILL.md`.

## All capabilities

| Area | Skill |
|------|-------|
| Full audit | `seo` |
| Single page | `seo-page` |
| Technical (9 categories) | `seo-technical` |
| Content / E-E-A-T | `seo-content` |
| Content brief | `seo-content-brief` |
| Schema.org | `seo-schema` |
| GEO / AI search | `seo-geo` |
| Sitemap | `seo-sitemap` |
| Images | `seo-images` |
| Strategic plan | `seo-plan` |
| Programmatic SEO | `seo-programmatic` |
| Competitor pages | `seo-competitor-pages` |
| Local SEO | `seo-local` |
| Maps intelligence | `seo-maps` |
| Hreflang | `seo-hreflang` |
| Google APIs | `seo-google` |
| Backlinks | `seo-backlinks` |
| Keyword clustering | `seo-cluster` |
| SXO | `seo-sxo` |
| Drift | `seo-drift` |
| E-commerce | `seo-ecommerce` |
| FLOW framework | `seo-flow` |
| Live DataForSEO | `seo-dataforseo` |

## Docs

| Document | Purpose |
|----------|---------|
| [docs/install.md](docs/install.md) | Install, flags, validate, troubleshooting |
| [docs/mcp-setup.md](docs/mcp-setup.md) | DataForSEO MCP for Cursor |
| [skills/cursor-seo-router/SKILL.md](skills/cursor-seo-router/SKILL.md) | Router skill map |
| [docs/porting-notes.md](docs/porting-notes.md) | Cursor vs Claude Code differences (maintainers) |
| [docs/upstream-sync.md](docs/upstream-sync.md) | Merge upstream releases |
| [docs/upstream/](docs/upstream/) | Upstream reference (architecture, commands) |
| [ATTRIBUTION.md](ATTRIBUTION.md) | License and upstream credit |

## Requirements

- **Cursor** with local plugins enabled
- **Python 3.10+** (3.12 recommended on macOS)
- **Optional:** Node.js 20+ for DataForSEO MCP via `npx`
- **Optional:** `--with-render` / `--with-pdf` for Playwright and PDF reports

## License

MIT — upstream © [AgriciDaniel](https://github.com/AgriciDaniel/claude-seo).
See [LICENSE](LICENSE) and [ATTRIBUTION.md](ATTRIBUTION.md).

# Cursor SEO

Cursor local-plugin port of [claude-seo v2.0.0](https://github.com/AgriciDaniel/claude-seo)
(MIT, by Agrici Daniel): **25 SEO skills + 18 inline agents** covering technical SEO,
E-E-A-T content quality, Schema.org, GEO/AI-search, local SEO + maps intelligence,
keyword clustering, SXO, drift monitoring, e-commerce, hreflang, Google APIs,
backlinks, and live DataForSEO data.

## Install

```bash
git clone https://github.com/khymerao/cursor-seo.git ~/.cursor/plugins/local/cursor-seo
cd ~/.cursor/plugins/local/cursor-seo && ./setup/setup.sh
# optional extras:
# ./setup/setup.sh --with-render   # Playwright Chromium for SPA rendering
# ./setup/setup.sh --with-pdf      # WeasyPrint/matplotlib for PDF/Excel reports
```

If your system `python3` is older than 3.10, point setup at a newer interpreter:

```bash
PYTHON=python3.12 ./setup/setup.sh
```

Reload Cursor (**Cmd+Shift+P → Reload Window**). Verify the install:

```bash
./setup/validate.sh
```

See [docs/install.md](docs/install.md) for flags, troubleshooting, and hook checks.

## Usage — prompts instead of `/seo` commands

Cursor has no plugin slash-command palette. Describe what you want in natural language;
the **`cursor-seo-router`** skill (or the trigger rule) maps your intent to the right
upstream skill. Full command map: [skills/cursor-seo-router/SKILL.md](skills/cursor-seo-router/SKILL.md).

| Upstream command | Say in Cursor (examples) |
|---|---|
| `/seo audit <url>` | «Зроби повний SEO-аудит example.com» / "Run a full SEO audit on example.com" |
| `/seo page <url>` | «Проаналізуй одну сторінку https://example.com/about» |
| `/seo technical <url>` | «Швидкий технічний SEO-чек https://example.com» |
| `/seo content <url>` | «Оціни E-E-A-T і якість контенту для <url>» |
| `/seo schema <url>` | «Перевір і згенеруй schema для <url>» |
| `/seo geo <url>` | «Оціни AI-citability / GEO для <url>» |
| `/seo sitemap <url>` | «Проаналізуй sitemap для example.com» |
| `/seo images <url>` | «Аудит зображень і alt-текстів на <url>» |
| `/seo local <url>` | «Локальний SEO-аудит для <business>» |
| `/seo maps <query>` | «Geo-grid / maps intelligence для <location>» |
| `/seo hreflang <url>` | «Перевір hreflang на багатомовному сайті» |
| `/seo google setup` | «Налаштуй Google APIs (GSC, PageSpeed, CrUX)» |
| `/seo backlinks <domain>` | «Аналіз беклінків для example.com» |
| `/seo cluster <seeds>` | «Кластеризація ключових слів за SERP overlap» |
| `/seo sxo <keyword>` | «SXO / SERP backwards analysis для <keyword>» |
| `/seo drift baseline <url>` | «Зніми SEO baseline для drift-моніторингу» |
| `/seo ecommerce <url>` | «E-commerce SEO для магазину <url>» |
| `/seo flow <stage>` | «FLOW framework prompt для Find/Leverage/Optimize/Win» |
| `/seo plan <type>` | «SEO-стратегія для SaaS / local / ecommerce» |
| `/seo dataforseo keywords <seed>` | «Підбери ключовики через DataForSEO для <seed>» |
| `/seo dataforseo serp <query>` | «Покажи топ-10 SERP по запиту '<query>' через DataForSEO» |

**Inline agents:** full audits run specialist agent prompts from `agents/` sequentially
in the current chat (not parallel subagents). See [docs/porting-notes.md](docs/porting-notes.md).

## Live data (DataForSEO)

Core audits work **zero-network** without any MCP server. For live SERP, keyword volume,
competitor, and trends data, configure the **`user-dataforseo`** MCP server in Cursor.

→ [docs/mcp-setup.md](docs/mcp-setup.md)  
→ Tool mapping: [skills/seo-dataforseo/references/cursor-mcp-mapping.md](skills/seo-dataforseo/references/cursor-mcp-mapping.md)

## Docs

| Document | Purpose |
|---|---|
| [docs/porting-notes.md](docs/porting-notes.md) | Claude Code → Cursor compatibility matrix |
| [docs/install.md](docs/install.md) | Install, flags, validate, troubleshooting |
| [docs/mcp-setup.md](docs/mcp-setup.md) | DataForSEO MCP for Cursor |
| [docs/upstream-sync.md](docs/upstream-sync.md) | Merge upstream claude-seo releases |
| [docs/upstream/](docs/upstream/) | Original upstream reference (ARCHITECTURE, COMMANDS, …) |
| [ATTRIBUTION.md](ATTRIBUTION.md) | Upstream credit and port deltas |

## Requirements

- **Cursor** with local plugins enabled
- **Python 3.10+** (3.12 recommended on macOS if system Python is older)
- **Optional:** Node.js 20+ only if you install the DataForSEO MCP server via `npx`
- **Optional:** `--with-render` / `--with-pdf` for Playwright and PDF report skills

## License

MIT — upstream content © [AgriciDaniel](https://github.com/AgriciDaniel/claude-seo).
See [LICENSE](LICENSE) and [ATTRIBUTION.md](ATTRIBUTION.md).

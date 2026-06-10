# DataForSEO MCP setup for Cursor

The **cursor-seo** plugin does **not** ship an MCP server. Core SEO audits run
zero-network. Live SERP, keyword, competitor, and trends data use the
**DataForSEO MCP server** you configure in Cursor.

In this port, the skill layer expects the server name **`user-dataforseo`** (your
existing Cursor MCP registration). Tool mapping:
[skills/seo-dataforseo/references/cursor-mcp-mapping.md](../skills/seo-dataforseo/references/cursor-mcp-mapping.md).

> **Do not** run upstream `extensions/dataforseo/install.sh` — it targets Claude Code's
> `~/.claude/settings.json`, not Cursor.

## Prerequisites

1. [DataForSEO account](https://app.dataforseo.com/register) with API credentials
2. **Node.js 20+** (for `npx dataforseo-mcp-server`)
3. cursor-seo installed ([install.md](install.md))

## Cursor MCP configuration

Add the DataForSEO MCP server in Cursor **Settings → Tools & MCP** (or edit your
MCP config JSON). Example using the official npm package:

```json
{
  "mcpServers": {
    "user-dataforseo": {
      "command": "npx",
      "args": ["-y", "dataforseo-mcp-server"],
      "env": {
        "DATAFORSEO_USERNAME": "your-login@example.com",
        "DATAFORSEO_PASSWORD": "your-api-password",
        "ENABLED_MODULES": "serp,labs,kw_data"
      }
    }
  }
}
```

### Environment variables

| Variable | Required | Description |
|---|---|---|
| `DATAFORSEO_USERNAME` | Yes | DataForSEO API login (email) |
| `DATAFORSEO_PASSWORD` | Yes | DataForSEO API password |
| `ENABLED_MODULES` | Yes | Comma-separated module list (controls which tools are exposed) |

Reload Cursor after saving MCP settings.

## Currently enabled modules (35 tools)

The reference mapping in this repo assumes **`ENABLED_MODULES=serp,labs,kw_data`**
(or equivalent) on the **`user-dataforseo`** server — **35 MCP tools** covering
these upstream command groups:

| Module | Tools (representative) | Upstream `/seo dataforseo` commands |
|---|---|---|
| **serp** | `serp_organic_live_advanced`, `serp_locations`, YouTube SERP tools | `serp`, `serp-youtube`, `youtube` |
| **labs** | Keyword ideas, difficulty, intent, competitors, domain metrics, historical, gap | `keywords`, `difficulty`, `intent`, `competitors`, `domain`, `ranked-keywords`, `gap`, `keywords-for-site`, `historical`, `top-searches` |
| **kw_data** | Google Ads search volume, Google Trends, DFS trends | `volume`, `trends` |

Full tool ↔ command table:
[cursor-mcp-mapping.md](../skills/seo-dataforseo/references/cursor-mcp-mapping.md).

### Verify connection

In a Cursor chat:

> «Покажи топ-10 SERP по запиту 'cursor ide' через DataForSEO»

The agent should call `serp_organic_live_advanced` via **`user-dataforseo`**.

If tools are missing, check Settings → Tools & MCP — server status should be green.

## Optional modules (not enabled by default)

Add these to `ENABLED_MODULES` to unlock additional upstream commands.
Each module adds API surface and cost exposure — enable only what you need.

| Module | Unlocks (examples) | Upstream commands |
|---|---|---|
| `backlinks` | Backlink summary, anchors, referring domains | `backlinks`, `intersection` (backlink overlap) |
| `onpage` | Lighthouse, on-page crawl, instant pages | `onpage`, `tech` |
| `content_analysis` | Content search, phrase trends, sentiment | `content` |
| `business_data` | Business listings, reviews | `listings` |
| `ai_optimization` | LLM mentions, AI visibility scrapers | `ai-mentions`, `ai-visibility` |

Example with optional modules:

```json
"ENABLED_MODULES": "serp,labs,kw_data,backlinks,onpage,content_analysis,business_data,ai_optimization"
```

Upstream ships up to **10 modules / 79+ tools** when fully enabled in Claude Code.
This Cursor port documents the **35-tool baseline** and optional expansion above.

### Fallbacks when a module is disabled

| Need | Fallback |
|---|---|
| Backlinks | `skills/seo-backlinks` (Moz API, Common Crawl, Bing Webmaster scripts) |
| On-page Lighthouse | `skills/seo-technical` + PageSpeed scripts |
| Content analysis | Ask user to paste exported data |
| AI visibility | `skills/seo-geo` (on-page citability heuristics) |

## Cost guardrails

Upstream cost tiers remain in force:

- `skills/seo-dataforseo/references/cost-tiers.md`
- `python scripts/dataforseo_costs.py check <endpoint>` before expensive calls

The agent should confirm with you before high-volume or bulk API operations.

## Troubleshooting

| Symptom | Fix |
|---|---|
| "DataForSEO tools not available" | Enable MCP server; Reload Window; check credentials |
| Wrong server name in agent | Skill expects **`user-dataforseo`** — rename your MCP entry or update mapping |
| `npx` not found | Install Node.js 20+ |
| Auth errors | Verify username/password at [app.dataforseo.com](https://app.dataforseo.com/) |
| Missing command (e.g. backlinks) | Add module to `ENABLED_MODULES` and reload |

## Reference docs

- Upstream DataForSEO extension readme: [docs/upstream/DATAFORSEO-README.md](upstream/DATAFORSEO-README.md)
- Upstream MCP overview: [docs/upstream/MCP-INTEGRATION.md](upstream/MCP-INTEGRATION.md)
- Port compatibility: [porting-notes.md](porting-notes.md)

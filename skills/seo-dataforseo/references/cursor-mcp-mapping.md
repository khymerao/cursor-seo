# Cursor adaptation: seo-dataforseo → user-dataforseo MCP

Upstream assumes `extensions/dataforseo/install.sh` registered a DataForSEO
MCP server in Claude Code with up to 10 modules / 79+ tools. In this Cursor
port, use the already-configured **`user-dataforseo`** MCP server instead.
Read the tool descriptor JSON before each call (mandatory for MCP tools).

## Currently enabled tools (35) and command coverage

| Upstream command group | user-dataforseo tools |
|---|---|
| `serp <query>` | `serp_organic_live_advanced`, `serp_locations` |
| `youtube <query>` | `serp_youtube_organic_live_advanced`, `serp_youtube_video_info_live_advanced`, `serp_youtube_video_comments_live_advanced`, `serp_youtube_video_subtitles_live_advanced`, `serp_youtube_locations` |
| `keywords <seed>` | `dataforseo_labs_google_keyword_ideas`, `dataforseo_labs_google_keyword_suggestions`, `dataforseo_labs_google_related_keywords`, `dataforseo_labs_google_keyword_overview` |
| `volume <keywords>` | `kw_data_google_ads_search_volume` (+ `kw_data_google_ads_locations`) |
| `difficulty <keywords>` | `dataforseo_labs_bulk_keyword_difficulty` |
| `intent <keywords>` | `dataforseo_labs_search_intent` |
| `trends <topic>` | `kw_data_google_trends_explore`, `kw_data_dfs_trends_explore`, `kw_data_dfs_trends_demography`, `kw_data_dfs_trends_subregion_interests` |
| `competitors <domain>` | `dataforseo_labs_google_competitors_domain`, `dataforseo_labs_google_serp_competitors` |
| `domain <domain>` | `dataforseo_labs_google_domain_rank_overview`, `dataforseo_labs_google_historical_rank_overview`, `dataforseo_labs_bulk_traffic_estimation` |
| `ranked-keywords <domain>` | `dataforseo_labs_google_ranked_keywords`, `dataforseo_labs_google_relevant_pages`, `dataforseo_labs_google_subdomains` |
| `gap <domain1> <domain2>` | `dataforseo_labs_google_domain_intersection`, `dataforseo_labs_google_page_intersection` |
| `keywords-for-site <domain>` | `dataforseo_labs_google_keywords_for_site` |
| `historical <keyword>` | `dataforseo_labs_google_historical_keyword_data`, `dataforseo_labs_google_historical_serps` |
| `top-searches` | `dataforseo_labs_google_top_searches` |
| *(utility)* | `dataforseo_labs_available_filters` — filter helper for Labs endpoints |
| *(utility)* | `kw_data_google_trends_categories` — Google Trends category list helper |

## Not enabled in the current server config

`backlinks`, `onpage` (Lighthouse/audit), `content_analysis`,
`business_data` (listings), `ai_optimization` (LLM mentions, AI visibility),
Bing/Yahoo SERP modules. Upstream commands relying on them (`backlinks`,
`onpage`, `content-analysis`, `listings`, `ai-mentions`, `ai-visibility`)
are unavailable until those modules are enabled in the DataForSEO MCP config
(`ENABLED_MODULES` env of the user's `user-dataforseo` server — see
`docs/mcp-setup.md`). Fallbacks: `skills/seo-backlinks` (Moz/Common Crawl
scripts) for backlinks; ask the user to paste exported data otherwise.

## Cost guardrails

Upstream cost tiers in `references/cost-tiers.md` still apply. Before
high-volume calls (bulk difficulty, historical SERPs), state the approximate
cost tier and get user confirmation, exactly as upstream specifies.

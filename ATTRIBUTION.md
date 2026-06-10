# Attribution

## Upstream

| Field | Value |
|---|---|
| Project | [AgriciDaniel/claude-seo](https://github.com/AgriciDaniel/claude-seo) |
| Version | **v2.0.0** |
| Commit | `dabfc1abb4ca9a4d7967242bf00d52593be56ed1` |
| License | MIT |
| Author | Agrici Daniel |

This repository (`khymerao/cursor-seo`) is a **Cursor IDE port** of the upstream plugin.
It preserves upstream skill bodies, agents, scripts, and tests wherever possible and
adds a thin Cursor adaptation layer.

## Vendored unchanged (from upstream v2.0.0)

These trees and files were copied from upstream without content edits:

| Path | Notes |
|---|---|
| `skills/` (25 upstream `seo*` skills) | Full skill bodies, references, evals |
| `agents/` | 18 agent prompt files |
| `scripts/` | ~50 Python analysis scripts |
| `data/` | e.g. `google-updates.json` |
| `schema/` | `templates.json` |
| `pdf/` | `google-seo-reference.md` |
| `tests/` | Upstream pytest suite |
| `hooks/validate-schema.py` | Schema validation logic |
| `requirements.txt` | Python dependencies |
| `LICENSE` | MIT (upstream copyright) |
| `docs/upstream/` | ARCHITECTURE, COMMANDS, MCP-INTEGRATION, TROUBLESHOOTING, README, DATAFORSEO-README |

## Added by this port (Cursor layer)

| Path | Purpose |
|---|---|
| `.cursor-plugin/plugin.json` | Cursor local-plugin manifest |
| `skills/cursor-seo-router/SKILL.md` | Entry router (replaces `/seo` slash commands) |
| `rules/cursor-seo-usage.mdc` | Agent-requestable SEO trigger rule |
| `hooks/hooks.json` | Cursor hook registration |
| `hooks/post-tool-use` | `postToolUse` wrapper → `validate-schema.py` |
| `setup/setup.sh` | Creates `.venv`, installs deps, optional flags |
| `setup/validate.sh` | Structural consistency checks |
| `skills/seo-dataforseo/references/cursor-mcp-mapping.md` | Maps upstream DataForSEO commands → `user-dataforseo` MCP tools |
| `docs/install.md` | Cursor install guide |
| `docs/mcp-setup.md` | DataForSEO MCP setup for Cursor |
| `docs/upstream-sync.md` | Upstream merge procedure |
| `docs/porting-notes.md` | Compatibility matrix |
| `docs/development/` | Port design and plan (internal) |
| `README.md` | This Cursor-first readme |
| `ATTRIBUTION.md` | This file |

## Modified (minimal patch)

| File | Change |
|---|---|
| `skills/seo-dataforseo/SKILL.md` | **Prerequisites + Error Handling** — Cursor override blocks (`<!-- CURSOR-OVERRIDE -->`) replace `extensions/dataforseo/install.sh` with `user-dataforseo` MCP + `docs/mcp-setup.md` (Fix 1) |
| `skills/seo-dataforseo/references/tool-catalog.md` | Prepended Cursor port note: only `ENABLED_MODULES` tools callable; see `cursor-mcp-mapping.md` (Fix 2) |
| `skills/seo-audit/SKILL.md` | Post-frontmatter override: sub-agents run inline/sequentially, not parallel (Fix 3) |
| `skills/seo/SKILL.md` | Post-frontmatter override: sub-agents run inline/sequentially, not parallel (Fix 3) |
| `hooks/post-tool-use` | Extension filter aligned with `validate-schema.py` valid_extensions (Fix 4) |
| `skills/seo-dataforseo/references/cursor-mcp-mapping.md` | Added utility tools `dataforseo_labs_available_filters`, `kw_data_google_trends_categories` (Fix 5) |
| `docs/install.md` | Documented advisory (non-blocking) schema hook behavior (Fix 6) |

**Trigger rule name:** `rules/cursor-seo-usage.mdc` (design doc referred to
`cursor-seo-triggers.mdc`; this port uses `-usage`).

No other upstream skill, agent, or script bodies were edited.

## Deliberately dropped from upstream

Not copied into this port (see design doc §3):

| Dropped | Reason |
|---|---|
| `branding/`, `screenshots/`, `assets/diagrams/` | Upstream marketing assets |
| `.devcontainer/`, `.github/` | Upstream CI/dev tooling |
| `install.sh`, `install.ps1`, `uninstall.*` | Replaced by `setup/setup.sh` |
| `.claude-plugin/marketplace.json` | Claude Code marketplace manifest |
| `extensions/` (7 of 8) | Optional third-party MCP extensions not patched for Cursor v1 |
| `CLAUDE.md`, `AGENTS.md`, `CONTRIBUTING.md`, community files | Claude Code–specific docs |
| Upstream root `README.md` | Preserved as `docs/upstream/README.md` |

**Kept from extensions:** `extensions/dataforseo/README.md` → `docs/upstream/DATAFORSEO-README.md` (reference only).

Optional extensions **not ported** (documented in router + `docs/upstream/MCP-INTEGRATION.md`):
Firecrawl, Banana/image-gen, Ahrefs, SE Ranking, Profound, Bing Webmaster, Unlighthouse.

## Supersedes seo-geo-cursor

This plugin replaces [khymerao/seo-geo-cursor](https://github.com/khymerao/seo-geo-cursor),
a narrower port of the Aaron SEO/GEO skill set. Feature mapping and migration notes:
[docs/porting-notes.md § Supersedes seo-geo-cursor](docs/porting-notes.md).

## License

MIT — see [LICENSE](LICENSE). Upstream MIT notice must remain in distributions of
vendored content.

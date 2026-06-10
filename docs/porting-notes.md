# Claude Code → Cursor porting notes

Compatibility reference for **cursor-seo** (port of [claude-seo v2.0.0](https://github.com/AgriciDaniel/claude-seo)).
Upstream pin: tag `v2.0.0`, commit `dabfc1abb4ca9a4d7967242bf00d52593be56ed1`.

## Summary

| Area | Claude Code (upstream) | Cursor (this port) |
|---|---|---|
| Entry point | `/seo <command>` slash commands | Natural language + `cursor-seo-router` skill + trigger rule |
| Sub-agents | 18 registered subagents, parallel dispatch | Inline sequential execution from `agents/*.md` |
| Hooks | `PostToolUse` → `$FILE_PATH` env var | `postToolUse` → JSON on stdin → `post-tool-use` wrapper |
| MCP / DataForSEO | `extensions/dataforseo/install.sh` | User's `user-dataforseo` MCP server (no bundled MCP) |
| Python | Host or project venv | Plugin `.venv` via `setup/setup.sh` |
| Credentials | `~/.config/claude-seo/` | **Same path** (scripts hardcode it — do not change) |
| Marketplace | `.claude-plugin/marketplace.json` | `.cursor-plugin/plugin.json` |

---

## §4 Router — slash commands → natural language

Upstream users typed `/seo <subcommand>`. Cursor has no plugin command palette;
`skills/cursor-seo-router/SKILL.md` maps user intent to the matching skill.

| Upstream command | Dispatch target |
|---|---|
| `/seo audit <url>` | `skills/seo/SKILL.md` orchestrator + inline agents (fixed sequence below) |
| `/seo page <url>` | `skills/seo-page/SKILL.md` |
| `/seo technical <url>` | `skills/seo-technical/SKILL.md` + `agents/seo-technical.md` |
| `/seo content <url>` | `skills/seo-content/SKILL.md` |
| `/seo content-brief …` | `skills/seo-content-brief/SKILL.md` |
| `/seo schema <url>` | `skills/seo-schema/SKILL.md` |
| `/seo geo <url>` | `skills/seo-geo/SKILL.md` |
| `/seo sitemap …` | `skills/seo-sitemap/SKILL.md` |
| `/seo images <url>` | `skills/seo-images/SKILL.md` |
| `/seo plan <type>` | `skills/seo-plan/SKILL.md` |
| `/seo programmatic …` | `skills/seo-programmatic/SKILL.md` |
| `/seo competitor-pages …` | `skills/seo-competitor-pages/SKILL.md` |
| `/seo local <url>` | `skills/seo-local/SKILL.md` |
| `/seo maps …` | `skills/seo-maps/SKILL.md` |
| `/seo hreflang …` | `skills/seo-hreflang/SKILL.md` |
| `/seo google …` | `skills/seo-google/SKILL.md` |
| `/seo backlinks …` | `skills/seo-backlinks/SKILL.md` |
| `/seo cluster …` | `skills/seo-cluster/SKILL.md` |
| `/seo sxo …` | `skills/seo-sxo/SKILL.md` |
| `/seo drift baseline\|compare\|history` | `skills/seo-drift/SKILL.md` |
| `/seo ecommerce …` | `skills/seo-ecommerce/SKILL.md` |
| `/seo flow …` | `skills/seo-flow/SKILL.md` |
| `/seo dataforseo <cmd>` | `skills/seo-dataforseo/SKILL.md` → `user-dataforseo` MCP |

**Not ported (optional extensions):** firecrawl, banana/image-gen, ahrefs, seranking,
profound, bing-webmaster, unlighthouse — see `docs/upstream/MCP-INTEGRATION.md`.

**Claude-isms in skill bodies** (e.g. text saying `/seo google setup`) are intentionally
**not rewritten**. The router and this document record the mapping; agents interpret user
phrasing in Cursor.

### Full-audit agent sequence

When the user requests a full audit, run inline agents **sequentially** (not in parallel):

1. `agents/seo-technical.md`
2. `agents/seo-content.md`
3. `agents/seo-schema.md`
4. `agents/seo-geo.md`
5. `agents/seo-local.md` — **only** if the site has a local/physical footprint
6. Synthesis via `skills/seo/references/thinking-framework.md` (10 principles)
7. Emit prioritized action plan per orchestrator report format

---

## Inline agent contract

Cursor plugins **cannot register custom subagents**. When a skill references an agent:

1. **Read** `agents/seo-<name>.md`.
2. **Ignore frontmatter** keys `model`, `maxTurns`, `tools` — these are Claude Code–specific.
3. **Execute** the body instructions in the **current chat context**, one agent after another.
4. **Do not** spawn parallel subagents or use the Task tool for SEO specialist dispatch.

This replaces upstream parallel subagent orchestration while keeping agent prompt bodies
vendored unchanged.

---

## §5 Hooks

| Aspect | Upstream (Claude Code) | Cursor port |
|---|---|---|
| Event | `PostToolUse` | `postToolUse` in `hooks/hooks.json` |
| Matcher | `Edit\|Write` | Handled inside `hooks/post-tool-use` (file extension filter) |
| Invocation | `validate-schema.py "$FILE_PATH"` | `post-tool-use` reads JSON stdin, resolves path, calls venv python |
| SessionStart / Stop | Not present upstream | Not added (via negativa) |

### Hook stdin JSON difference

**Upstream:** Claude passed the edited file path as the **`$FILE_PATH` environment variable**.

**Cursor:** `hooks/post-tool-use` reads **JSON from stdin**:

```json
{
  "file_path": "relative/or/absolute/path",
  "cwd": "/current/working/directory"
}
```

The wrapper also accepts `"path"` as an alias for `"file_path"`. Relative paths are
resolved against `cwd`. Only schema-relevant files are validated (`*.html`, `*.json`,
`*schema*.md`, `*SCHEMA*.md`). On validation failure the hook prints
`{"additional_context": "…"}` for the agent; exit code is always `0` (non-blocking).

**If hook blocking is flaky:** skills document manual artifact checks as fallback —
same pattern as the seo-geo-cursor port.

**Verify hooks:** Cursor **Settings → Hooks** after Reload Window; ensure `post-tool-use`
is listed for the cursor-seo plugin.

---

## §6 MCP / DataForSEO

| Aspect | Upstream | Cursor port |
|---|---|---|
| MCP server | Installed via `extensions/dataforseo/install.sh` into Claude settings | **None bundled** — use existing `user-dataforseo` MCP |
| Network default | Zero-network core; live data optional | Same |
| Skill patch | N/A | `skills/seo-dataforseo/SKILL.md` Prerequisites note + `references/cursor-mcp-mapping.md` |
| Cost guardrails | `references/cost-tiers.md` | Unchanged |
| Fallback without MCP | Paste exported data | Same + `skills/seo-backlinks` free APIs for backlinks |

See [docs/mcp-setup.md](mcp-setup.md) for Cursor MCP configuration.

---

## §7 Python runtime

| Aspect | Upstream | Cursor port |
|---|---|---|
| Venv location | User/host dependent | `$CURSOR_PLUGIN_ROOT/.venv` (plugin root) |
| Setup | Upstream `install.sh` | `setup/setup.sh` |
| Core deps | `requirements.txt` minus heavy extras | Always installed |
| `--with-render` | Playwright Chromium | Optional; enables SPA rendering in scripts |
| `--with-pdf` | WeasyPrint, matplotlib, openpyxl | Optional; PDF/Excel report skills |
| Degradation | Raw HTML fetch if no Playwright | Same |
| Script convention | Various | `"$CURSOR_PLUGIN_ROOT/.venv/bin/python" scripts/<name>.py` |

If `.venv` is missing, the router instructs running `setup/setup.sh` before script-backed flows.
Zero-dependency skills (schema templates, rubrics) work without the venv.

---

## Credentials path

Google API credentials (GSC, PageSpeed, CrUX, GA4) remain at:

```
~/.config/claude-seo/
```

Upstream scripts **hardcode this path**. The Cursor port does **not** relocate it.
Run the Google setup flow via `skills/seo-google/SKILL.md` (user prompt: "налаштуй Google APIs").

Drift baselines use upstream cache paths (e.g. `~/.cache/claude-seo/drift/baselines.db`).

---

## Test suite baseline (Task 8)

Host-independent subset (schema, URL safety, portability):

```bash
.venv/bin/python -m pytest tests/test_url_safety.py tests/test_schema_v2.py tests/test_portability.py -q
```

**Baseline: 107 passed, 3 failed** (110 total)

| Failure | Cause | Expected? |
|---|---|---|
| `test_agents_md_covers_all_target_platforms` | `AGENTS.md` not vendored (Claude Code doc) | Yes |
| `test_agents_md_documents_portability_check` | same | Yes |
| `test_agents_md_tool_mapping_table_includes_codex_cline_aider` | same | Yes |

Full suite (`pytest tests/ -q`) includes upstream tests for dropped extensions
(`.claude-plugin/marketplace.json`, `install.sh`, etc.) — **many failures expected**
in the Cursor port. Do not "fix" by restoring dropped upstream files.

Quality gates that **must pass** before release:

```bash
./setup/validate.sh
python3 scripts/portability_check.py
.venv/bin/python -m pytest tests/test_url_safety.py tests/test_schema_v2.py tests/test_portability.py -q
# expect 107/110 (3 AGENTS.md failures)
```

---

## Superpowers coexistence

Same pattern as seo-geo-cursor. No hook conflicts — cursor-seo registers only `postToolUse`.

| Situation | Use |
|---|---|
| SEO **deliverable** (audit, report, schema, keywords, brief) | `cursor-seo-router` / `seo-*` skills directly — **no brainstorming gate** |
| **Building code** from SEO findings (theme module, automation, plugin) | Superpowers `brainstorming` → `writing-plans` first |
| Debugging / tests for SEO-related code | Superpowers `systematic-debugging`, `test-driven-development` |

Stated in `skills/cursor-seo-router/SKILL.md` and `rules/cursor-seo-usage.mdc`.

---

## Supersedes seo-geo-cursor

**cursor-seo** replaces [khymerao/seo-geo-cursor](https://github.com/khymerao/seo-geo-cursor).
Disable the old plugin (`~/.cursor/plugins/local/seo-geo-cursor`) and use cursor-seo instead.
Project memory files (e.g. `memory/hot-cache.md` in user repos) remain usable.

### Feature mapping

| seo-geo-cursor skill | cursor-seo equivalent |
|---|---|
| `seo-geo-router` | `cursor-seo-router` |
| `keyword-research` | `seo-dataforseo` + `seo-cluster` + `seo-plan` |
| `serp-analysis` | `seo-dataforseo` (SERP tools) + `seo-sxo` |
| `competitor-analysis` | `seo-dataforseo` (competitors, domain, gap) + `seo-competitor-pages` |
| `content-gap-analysis` | `seo-cluster` + `seo-plan` + orchestrator |
| `seo-content-writer` | `seo-content-brief` + `seo-content` |
| `geo-content-optimizer` | `seo-geo` |
| `meta-tags-optimizer` | `seo-page` + `seo-content` on-page sections |
| `schema-markup-generator` | `seo-schema` + `scripts/schema_generate.py` |
| `on-page-seo-auditor` | `seo-page` + `seo-content` |
| `technical-seo-checker` | `seo-technical` + `agents/seo-technical.md` |
| `internal-linking-optimizer` | `seo` orchestrator / `seo-plan` internal linking guidance |
| `content-refresher` | `seo-content` + `seo-drift` compare/history |
| `rank-tracker` | `seo-dataforseo` (historical/ranked keywords) + manual exports |
| `backlink-analyzer` | `seo-backlinks` + DataForSEO backlinks module (if MCP enabled) |
| `performance-reporter` | Full `seo audit` orchestrator report format |
| `alert-manager` | Not ported 1:1 — use `seo-drift` for regression alerts |
| `content-quality-auditor` (CORE-EEAT 80-item) | `seo-content` E-E-A-T analysis + `seo` quality gates / thinking framework |
| `domain-authority-auditor` (CITE 40-item) | `seo-backlinks` + `seo` trust signals; no separate CITE rubric |
| `entity-optimizer` | `seo-schema` (Organization, sameAs) + `seo-geo` entity signals |
| `memory-management` | User project `memory/` files (not plugin-managed) |
| Bundled seo-geo MCP connectors | **Dropped** — use `user-dataforseo` + free scripts instead |

### Scoring rubrics

| seo-geo-cursor | cursor-seo |
|---|---|
| CORE-EEAT 80-item veto scoring | `skills/seo-content` E-E-A-T depth + orchestrator quality gates in `skills/seo/references/thinking-framework.md` |
| CITE 40-item domain trust | Backlink/trust analysis via `seo-backlinks`, `seo-dataforseo` (when enabled), and full-audit synthesis |

The upstream claude-seo framework is broader (25 skills, 18 agents, ~50 scripts) than
seo-geo-cursor's Aaron skill tree; most seo-geo workflows map to **multiple** upstream skills.

---

## Versioning

Plugin version in `.cursor-plugin/plugin.json`: `2.0.0-cursor.N` where **N** increments
on each Cursor-port release after upstream merges. See [upstream-sync.md](upstream-sync.md).

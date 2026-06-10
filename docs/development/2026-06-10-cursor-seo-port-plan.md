# cursor-seo Port Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking. Mechanical file-writing tasks should be dispatched to **Composer 2.5** (`composer-2.5-fast`) subagents; review happens in the parent session.

**Goal:** Port claude-seo v2.0.0 (25 skills, 18 agents, ~50 scripts, hooks, DataForSEO) to the Cursor local plugin `cursor-seo` at `~/.cursor/plugins/local/cursor-seo`, replacing seo-geo-cursor.

**Architecture:** Vendored upstream content + thin Cursor layer (manifest, router skill, trigger rule, hooks wrapper, setup scripts, docs). Sub-agents run inline and sequentially. No bundled MCP server; live data via the user's existing `user-dataforseo` MCP.

**Tech Stack:** Cursor plugin manifest, Markdown skills, Bash hooks/scripts, Python 3.10+ venv (requests, bs4, lxml, trafilatura; optional playwright, weasyprint).

**Spec:** `docs/development/2026-06-10-cursor-seo-port-design.md`
**Upstream pin:** `AgriciDaniel/claude-seo` tag `v2.0.0`, commit `dabfc1abb4ca9a4d7967242bf00d52593be56ed1`. Local clone: `~/work-porting/claude-seo`.
**Repo / install dir (same path):** `~/.cursor/plugins/local/cursor-seo` → `git@github.com:khymerao/cursor-seo.git`

---

## File structure (final)

| Path | Origin | Responsibility |
|---|---|---|
| `.cursor-plugin/plugin.json` | NEW | Cursor manifest |
| `skills/seo*/` (25 dirs) | VENDORED | Upstream skill content |
| `skills/cursor-seo-router/SKILL.md` | NEW | Entry point, command mapping, inline-agent contract |
| `agents/*.md` (18) | VENDORED | Specialist prompts, executed inline |
| `scripts/*.py` (~50) | VENDORED | Execution layer |
| `data/`, `schema/`, `pdf/` | VENDORED | Reference data |
| `hooks/hooks.json` | NEW | Cursor hook registration |
| `hooks/post-tool-use` | NEW | stdin-JSON wrapper → `validate-schema.py` |
| `hooks/validate-schema.py` | VENDORED | Schema artifact validation |
| `rules/cursor-seo-usage.mdc` | NEW | Agent-requestable trigger rule |
| `setup/setup.sh` | NEW | venv + deps (+ optional render/pdf) |
| `setup/validate.sh` | NEW | Manifest/structure consistency checks |
| `skills/seo-dataforseo/references/cursor-mcp-mapping.md` | NEW | 22 commands → `user-dataforseo` tools |
| `requirements.txt`, `tests/` (12 files) | VENDORED | Deps + upstream test suite |
| `docs/upstream/` | VENDORED | Original README/ARCHITECTURE/COMMANDS/MCP-INTEGRATION |
| `README.md`, `docs/*.md`, `ATTRIBUTION.md`, `LICENSE` | NEW/VENDORED | Cursor-first docs + MIT attribution |

---

### Task 1: Scaffold skeleton + manifest

**Files:**
- Create: `.cursor-plugin/plugin.json`, `.gitignore`

- [ ] **Step 1: Write `.cursor-plugin/plugin.json`**

```json
{
  "name": "cursor-seo",
  "displayName": "Cursor SEO",
  "version": "2.0.0-cursor.1",
  "description": "Cursor port of claude-seo v2.0.0: 25 SEO skills + 18 inline agents covering technical SEO, E-E-A-T, schema, GEO/AEO, local SEO, maps, clustering, e-commerce, i18n, Google APIs, and DataForSEO live data.",
  "author": { "name": "khymerao", "email": "hello@khymerao.com" },
  "homepage": "https://github.com/khymerao/cursor-seo",
  "repository": "https://github.com/khymerao/cursor-seo",
  "license": "MIT",
  "keywords": ["cursor-plugin", "seo", "geo", "schema", "e-e-a-t", "dataforseo", "claude-seo-port"],
  "skills": "./skills/",
  "rules": "./rules/",
  "hooks": "./hooks/hooks.json"
}
```

Note: no `mcpServers` key — the plugin ships no MCP server (design §6).

- [ ] **Step 2: Write `.gitignore`**

```gitignore
.venv/
__pycache__/
*.pyc
.DS_Store
.pytest_cache/
*.egg-info/
```

- [ ] **Step 3: Validate JSON and commit**

Run: `python3 -m json.tool .cursor-plugin/plugin.json > /dev/null && echo OK`
Expected: `OK`

```bash
git add -A && git commit -m "feat: scaffold cursor-seo plugin manifest"
```

---

### Task 2: Vendor upstream content (pinned v2.0.0)

**Files:**
- Create: `skills/` (25 dirs), `agents/`, `scripts/`, `data/`, `schema/`, `pdf/`, `hooks/validate-schema.py`, `requirements.txt`, `tests/`, `docs/upstream/`, `LICENSE`

- [ ] **Step 1: Verify upstream pin**

Run: `git -C ~/work-porting/claude-seo rev-parse HEAD`
Expected: `dabfc1abb4ca9a4d7967242bf00d52593be56ed1`
(If the clone is missing: `git clone --depth 1 --branch v2.0.0 https://github.com/AgriciDaniel/claude-seo.git ~/work-porting/claude-seo`)

- [ ] **Step 2: Copy vendored trees**

```bash
cd ~/.cursor/plugins/local/cursor-seo
UP=~/work-porting/claude-seo
cp -R "$UP/skills" ./skills
cp -R "$UP/agents" ./agents
cp -R "$UP/scripts" ./scripts
cp -R "$UP/data" ./data
cp -R "$UP/schema" ./schema
cp -R "$UP/pdf" ./pdf
cp -R "$UP/tests" ./tests
mkdir -p hooks docs/upstream
cp "$UP/hooks/validate-schema.py" hooks/validate-schema.py
cp "$UP/requirements.txt" requirements.txt
cp "$UP/LICENSE" LICENSE
cp "$UP/README.md" docs/upstream/README.md
cp "$UP/docs/ARCHITECTURE.md" "$UP/docs/COMMANDS.md" "$UP/docs/MCP-INTEGRATION.md" "$UP/docs/TROUBLESHOOTING.md" docs/upstream/
cp "$UP/extensions/dataforseo/README.md" docs/upstream/DATAFORSEO-README.md
```

Deliberately NOT copied (design §3): `branding/`, `screenshots/`, `assets/`, `.devcontainer/`, `.github/`, `install.*`, `uninstall.*`, `.claude-plugin/`, `extensions/` (except the DataForSEO README above), `CLAUDE.md`, community files.

- [ ] **Step 3: Sanity-count vendored content**

Run: `ls -d skills/seo*/ | wc -l && ls agents/*.md | wc -l && ls scripts/*.py | wc -l`
Expected: `25` skills (incl. `skills/seo/`), `18` agents, `50±2` scripts.

- [ ] **Step 4: Run upstream portability check**

Run: `python3 scripts/portability_check.py`
Expected: exit 0, no `error`-severity findings (warnings about `maxTurns`/tool comments are acceptable).

- [ ] **Step 5: Commit**

```bash
git add -A && git commit -m "feat: vendor claude-seo v2.0.0 (dabfc1a) skills, agents, scripts, data, tests"
```

---

### Task 3: Python runtime (`setup/setup.sh`)

**Files:**
- Create: `setup/setup.sh`

- [ ] **Step 1: Write `setup/setup.sh`**

```bash
#!/usr/bin/env bash
# Creates the plugin venv and installs dependencies.
# Usage: setup/setup.sh [--with-render] [--with-pdf]
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WITH_RENDER=0; WITH_PDF=0
for arg in "$@"; do
  case "$arg" in
    --with-render) WITH_RENDER=1 ;;
    --with-pdf)    WITH_PDF=1 ;;
    *) echo "Unknown flag: $arg" >&2; exit 1 ;;
  esac
done

PY="${PYTHON:-python3}"
"$PY" -c 'import sys; sys.exit(0 if sys.version_info >= (3,10) else 1)' \
  || { echo "ERROR: Python 3.10+ required" >&2; exit 1; }

[[ -d "$ROOT/.venv" ]] || "$PY" -m venv "$ROOT/.venv"
VPY="$ROOT/.venv/bin/python"
"$VPY" -m pip install --quiet --upgrade pip

# Core deps (always): everything except heavy optional extras
grep -vE '^(playwright|weasyprint|matplotlib|openpyxl)' "$ROOT/requirements.txt" \
  | "$VPY" -m pip install --quiet -r /dev/stdin

if [[ "$WITH_RENDER" == 1 ]]; then
  "$VPY" -m pip install --quiet 'playwright>=1.59.0,<2.0.0'
  "$VPY" -m playwright install chromium
fi
if [[ "$WITH_PDF" == 1 ]]; then
  "$VPY" -m pip install --quiet 'weasyprint>=68.1,<70.0' 'matplotlib>=3.8.0,<4.0.0' 'openpyxl>=3.1.5,<4.0.0'
fi

echo "OK: venv ready at $ROOT/.venv (render=$WITH_RENDER pdf=$WITH_PDF)"
```

- [ ] **Step 2: Make executable and run**

Run: `chmod +x setup/setup.sh && ./setup/setup.sh`
Expected: `OK: venv ready at .../.venv (render=0 pdf=0)`

- [ ] **Step 3: Verify a core script imports**

Run: `.venv/bin/python -c "import bs4, lxml, trafilatura, requests; print('deps OK')"`
Expected: `deps OK`
Run: `.venv/bin/python scripts/parse_html.py --help | head -3`
Expected: usage text, exit 0.

- [ ] **Step 4: Commit**

```bash
git add setup/setup.sh && git commit -m "feat: add venv setup script with optional render/pdf extras"
```

---

### Task 4: Hooks (postToolUse)

**Files:**
- Create: `hooks/hooks.json`, `hooks/post-tool-use`

- [ ] **Step 1: Write `hooks/hooks.json`**

```json
{
  "version": 1,
  "hooks": {
    "postToolUse": [
      { "command": "./hooks/post-tool-use" }
    ]
  }
}
```

- [ ] **Step 2: Write `hooks/post-tool-use`** (Cursor passes JSON on stdin, unlike Claude's `$FILE_PATH`)

```bash
#!/usr/bin/env bash
set -euo pipefail

INPUT="$(cat 2>/dev/null || true)"
FILE="$(printf '%s' "$INPUT" | python3 -c 'import json,sys; d=json.load(sys.stdin); print(d.get("file_path","") or d.get("path",""))' 2>/dev/null || true)"
CWD="$(printf '%s' "$INPUT" | python3 -c 'import json,sys; d=json.load(sys.stdin); print(d.get("cwd",""))' 2>/dev/null || true)"

[[ -n "$FILE" ]] || exit 0
[[ "$FILE" = /* ]] || FILE="${CWD:-$(pwd)}/$FILE"
[[ -f "$FILE" ]] || exit 0

# Only schema-bearing artifacts are worth validating (mirrors upstream Edit|Write matcher intent)
case "$FILE" in
  *.html|*.json|*schema*.md|*SCHEMA*.md) ;;
  *) exit 0 ;;
esac

PLUGIN_ROOT="${CURSOR_PLUGIN_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
PY="$PLUGIN_ROOT/.venv/bin/python"
[[ -x "$PY" ]] || PY="python3"

if ! OUT="$("$PY" "$PLUGIN_ROOT/hooks/validate-schema.py" "$FILE" 2>&1)"; then
  MSG="$(printf '%s' "$OUT" | tail -3 | python3 -c 'import json,sys; print(json.dumps(sys.stdin.read()))')"
  printf '{"additional_context": %s}\n' "$MSG"
fi
exit 0
```

Behavior choice: validation failures emit `additional_context` (advisory) rather than blocking — upstream's hook is advisory too (it lints schema after writes). No exit-code-2 gating.

- [ ] **Step 3: Test the wrapper with fake stdin**

Run:
```bash
chmod +x hooks/post-tool-use
echo '{"file_path": "/tmp/nonexistent.html", "cwd": "/tmp"}' | ./hooks/post-tool-use; echo "exit=$?"
```
Expected: `exit=0`, no output (file does not exist → silent pass).

Run:
```bash
printf '<html><head></head><body>no schema</body></html>' > /tmp/cursor-seo-hook-test.html
echo '{"file_path": "/tmp/cursor-seo-hook-test.html"}' | ./hooks/post-tool-use; echo "exit=$?"
```
Expected: `exit=0`; JSON `additional_context` line only if `validate-schema.py` flags the file (inspect output, both silent-pass and advisory are acceptable).

- [ ] **Step 4: Commit**

```bash
git add hooks/ && git commit -m "feat: port PostToolUse schema validation hook to Cursor postToolUse"
```

---

### Task 5: Router skill

**Files:**
- Create: `skills/cursor-seo-router/SKILL.md`

- [ ] **Step 1: Write `skills/cursor-seo-router/SKILL.md`**

````markdown
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
````

- [ ] **Step 2: Verify frontmatter parses + portability**

Run: `python3 scripts/portability_check.py 2>&1 | grep -i 'cursor-seo-router' || echo "router OK (no findings)"`
Expected: `router OK (no findings)` or only `info`-level findings.

- [ ] **Step 3: Commit**

```bash
git add skills/cursor-seo-router/ && git commit -m "feat: add cursor-seo-router skill replacing /seo commands"
```

---

### Task 6: Trigger rule

**Files:**
- Create: `rules/cursor-seo-usage.mdc`

- [ ] **Step 1: Write `rules/cursor-seo-usage.mdc`**

```markdown
---
description: Route SEO requests to cursor-seo-router or a specific seo-* skill. Use when user mentions SEO, audit, schema, GEO, AI Overviews, E-E-A-T, Core Web Vitals, sitemap, keywords, backlinks, local SEO, maps, hreflang, DataForSEO.
alwaysApply: false
---

# Cursor SEO Triggers

When the user request involves SEO:

1. Load skill `cursor-seo-router` for open-ended or multi-part goals.
2. Load the specific `seo-*` skill directly when intent is unambiguous
   (e.g. `seo-schema` for "generate schema markup").
3. For live data (SERP, keyword volume, backlinks-by-API), prefer the
   `user-dataforseo` MCP server; fallback is paste-data per
   `skills/seo-dataforseo/references/cursor-mcp-mapping.md`.
4. Python scripts run from the plugin venv:
   `~/.cursor/plugins/local/cursor-seo/.venv/bin/python`.

## Superpowers priority

- SEO **deliverables** → cursor-seo-router / seo-* skills (skip brainstorming).
- SEO **implementation in code** → Superpowers brainstorming first unless the
  user says otherwise.
```

- [ ] **Step 2: Commit**

```bash
git add rules/ && git commit -m "feat: add agent-requestable SEO trigger rule"
```

---

### Task 7: DataForSEO MCP adaptation

**Files:**
- Create: `skills/seo-dataforseo/references/cursor-mcp-mapping.md`
- Modify: `skills/seo-dataforseo/SKILL.md` (Prerequisites section only)

- [ ] **Step 1: Write `skills/seo-dataforseo/references/cursor-mcp-mapping.md`**

```markdown
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
```

- [ ] **Step 2: Patch `skills/seo-dataforseo/SKILL.md` Prerequisites**

Find the `## Prerequisites` section (begins near line 30). Insert directly under the heading:

```markdown
> **Cursor port:** the DataForSEO MCP server is configured in Cursor as
> `user-dataforseo` (Settings → Tools & MCP). Do NOT run
> `extensions/dataforseo/install.sh` — it targets Claude Code. Tool coverage
> and command mapping: `references/cursor-mcp-mapping.md`.
```

Leave the rest of the file untouched (upstream-sync friendliness).

- [ ] **Step 3: Verify MCP is reachable (live check)**

Ask the agent executing this plan to call `user-dataforseo` tool
`serp_locations` (read its descriptor JSON first) with a trivial query.
Expected: non-error response listing locations.

- [ ] **Step 4: Commit**

```bash
git add skills/seo-dataforseo/ && git commit -m "feat: adapt seo-dataforseo to user-dataforseo MCP with tool mapping"
```

---

### Task 8: Validation script + test run

**Files:**
- Create: `setup/validate.sh`

- [ ] **Step 1: Write `setup/validate.sh`**

```bash
#!/usr/bin/env bash
# Structural consistency checks for the cursor-seo plugin.
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ERR=0
fail() { echo "ERROR: $*" >&2; ERR=1; }
ok()   { echo "OK: $*"; }

# 1. Manifest is valid JSON and referenced paths exist
M="$ROOT/.cursor-plugin/plugin.json"
python3 -m json.tool "$M" > /dev/null || fail "plugin.json invalid JSON"
for key in skills rules; do
  p="$(python3 -c "import json;print(json.load(open('$M')).get('$key',''))")"
  [[ -d "$ROOT/${p#./}" ]] && ok "$key dir exists" || fail "$key path missing: $p"
done
h="$(python3 -c "import json;print(json.load(open('$M')).get('hooks',''))")"
[[ -f "$ROOT/${h#./}" ]] && ok "hooks.json exists" || fail "hooks path missing: $h"
python3 -m json.tool "$ROOT/hooks/hooks.json" > /dev/null || fail "hooks.json invalid JSON"

# 2. Hook scripts executable
[[ -x "$ROOT/hooks/post-tool-use" ]] && ok "post-tool-use executable" || fail "post-tool-use not executable"

# 3. Counts: 25 upstream skills + router, 18 agents
S=$(ls -d "$ROOT"/skills/seo*/ 2>/dev/null | wc -l | tr -d ' ')
[[ "$S" == "25" ]] && ok "25 upstream skills" || fail "expected 25 seo* skills, got $S"
[[ -f "$ROOT/skills/cursor-seo-router/SKILL.md" ]] && ok "router present" || fail "router missing"
A=$(ls "$ROOT"/agents/*.md 2>/dev/null | wc -l | tr -d ' ')
[[ "$A" == "18" ]] && ok "18 agents" || fail "expected 18 agents, got $A"

# 4. Every SKILL.md has name + description frontmatter
while IFS= read -r f; do
  head -20 "$f" | grep -q '^name:' || fail "missing name: $f"
  head -20 "$f" | grep -q '^description:' || fail "missing description: $f"
done < <(find "$ROOT/skills" -name SKILL.md)
ok "skill frontmatter scanned"

# 5. Upstream portability lint
( cd "$ROOT" && python3 scripts/portability_check.py > /dev/null ) \
  && ok "portability_check passed" || fail "portability_check failed"

[[ $ERR -eq 0 ]] && echo "VALIDATION PASSED" || { echo "VALIDATION FAILED" >&2; exit 1; }
```

- [ ] **Step 2: Run validation**

Run: `chmod +x setup/validate.sh && ./setup/validate.sh`
Expected: `VALIDATION PASSED`

- [ ] **Step 3: Run host-independent upstream tests**

Run:
```bash
.venv/bin/python -m pip install --quiet pytest
.venv/bin/python -m pytest tests/test_url_safety.py tests/test_schema_v2.py tests/test_portability.py -q
```
Expected: all pass. (Known acceptable: skips for missing optional deps.)
Then best-effort the rest, allowing failures only from missing Claude host or optional deps (playwright/weasyprint):
```bash
.venv/bin/python -m pytest tests/ -q || true
```
Record results in `docs/porting-notes.md` (Task 9).

- [ ] **Step 4: Commit**

```bash
git add setup/validate.sh && git commit -m "feat: add structural validation script; record test baseline"
```

---

### Task 9: Documentation + attribution

**Files:**
- Create: `README.md`, `ATTRIBUTION.md`, `docs/porting-notes.md`, `docs/install.md`, `docs/mcp-setup.md`, `docs/upstream-sync.md`

- [ ] **Step 1: Write `README.md`** — Cursor-first, structure:

```markdown
# Cursor SEO

Cursor local-plugin port of [claude-seo v2.0.0](https://github.com/AgriciDaniel/claude-seo)
(MIT, by Agrici Daniel): 25 SEO skills + 18 inline agents — technical SEO,
E-E-A-T content quality, Schema.org, GEO/AI-search, local SEO + maps,
clustering, SXO, drift monitoring, e-commerce, hreflang, Google APIs,
backlinks, and live DataForSEO data.

## Install

git clone https://github.com/khymerao/cursor-seo.git ~/.cursor/plugins/local/cursor-seo
cd ~/.cursor/plugins/local/cursor-seo && ./setup/setup.sh
# optional: ./setup/setup.sh --with-render --with-pdf

Reload Cursor (Cmd+Shift+P → Reload Window). Verify: ./setup/validate.sh

## Usage — prompts instead of /seo commands

| Upstream | Say in Cursor |
|---|---|
| /seo audit example.com | "Зроби повний SEO-аудит example.com" |
| /seo schema <url> | "Перевір і згенеруй schema для <url>" |
| /seo geo <url> | "Оціни AI-citability / GEO для <url>" |
| /seo dataforseo keywords <seed> | "Підбери ключовики через DataForSEO для <seed>" |

Full command map: skills/cursor-seo-router/SKILL.md.

## Live data (DataForSEO)

Requires a DataForSEO MCP server in Cursor (docs/mcp-setup.md). The core
plugin works zero-network without it.

## Docs

porting-notes · install · mcp-setup · upstream-sync · docs/upstream/ (original)

## License

MIT. Upstream content © AgriciDaniel (see ATTRIBUTION.md).
```

- [ ] **Step 2: Write `ATTRIBUTION.md`** — list: upstream repo/tag/SHA; vendored-unchanged trees; files added (manifest, router, rule, hooks.json, post-tool-use, setup/*, docs except docs/upstream, cursor-mcp-mapping.md); files modified (seo-dataforseo SKILL.md Prerequisites note only); files dropped (per Task 2 Step 2 list).

- [ ] **Step 3: Write `docs/porting-notes.md`** — the compatibility matrix from the design doc §4–§7 plus: inline-agent contract, hook stdin-JSON difference, credentials path kept at `~/.config/claude-seo/`, test-suite baseline from Task 8, Superpowers coexistence table, "supersedes seo-geo-cursor" note with feature mapping (CORE-EEAT/CITE scoring → upstream `seo-content`/E-E-A-T + `seo` quality gates).

- [ ] **Step 4: Write `docs/install.md`, `docs/mcp-setup.md`, `docs/upstream-sync.md`**

- `install.md`: clone, setup.sh flags, validate.sh, reload, troubleshooting (venv missing, python < 3.10, hook not firing → check Settings → Hooks).
- `mcp-setup.md`: DataForSEO MCP for Cursor — server config example with `npx dataforseo-mcp-server` (env: `DATAFORSEO_USERNAME`, `DATAFORSEO_PASSWORD`, `ENABLED_MODULES`), note that this user's server is `user-dataforseo`, list currently enabled modules vs optional ones (backlinks, onpage, content_analysis, business_data, ai_optimization) and that enabling them unlocks the corresponding upstream commands.
- `upstream-sync.md`: procedure — fetch upstream tag → diff vendored trees (`git diff --no-index`) → re-apply the single SKILL.md patch → rerun validate.sh + portability + pytest subset → bump `version` suffix `-cursor.N`.

- [ ] **Step 5: Run validate + commit**

```bash
./setup/validate.sh && git add -A && git commit -m "docs: add Cursor-first README, attribution, porting notes, install/MCP/sync guides"
git push origin main
```

---

### Task 10: Replace seo-geo-cursor

**Files:**
- None in this repo (operations on the old plugin)

- [ ] **Step 1: Disable old plugin locally**

```bash
mv ~/.cursor/plugins/local/seo-geo-cursor ~/.cursor/plugins/_archive-seo-geo-cursor
```
(Keep the backup dir; do not delete — user data safety.)

- [ ] **Step 2: Mark old repo superseded**

In `~/.cursor/plugins/_archive-seo-geo-cursor`: prepend to `README.md`:
`> **Superseded by [cursor-seo](https://github.com/khymerao/cursor-seo)** — a port of the broader claude-seo v2.0.0. This repo is archived.`
Commit, push, then: `gh repo archive khymerao/seo-geo-cursor --yes`

- [ ] **Step 3: Verify no stale references**

Run: `ls ~/.cursor/plugins/local/` → expected: `cursor-seo`, `dormouse`, `thinking-skills` (no seo-geo-cursor).
Check Cursor Settings → Rules: `seo-geo-triggers.mdc` gone after Reload Window.

---

### Task 11: End-to-end smoke test

- [ ] **Step 1: Reload Cursor** (user action: Cmd+Shift+P → Reload Window) and confirm `cursor-seo` appears in Settings → Plugins, its skills under Rules → Agent Decides, and the hook under Settings → Hooks.

- [ ] **Step 2: Script smoke**

```bash
cd ~/.cursor/plugins/local/cursor-seo
.venv/bin/python scripts/fetch_page.py https://example.com | head -20
.venv/bin/python scripts/parse_html.py --help > /dev/null && echo "parse OK"
```
Expected: HTML/extracted content for example.com; `parse OK`.

- [ ] **Step 3: Router smoke (in a fresh chat)**

Prompt: "Зроби швидкий технічний SEO-чек https://example.com". Verify the
agent loads `cursor-seo-router` → `seo-technical` + inline
`agents/seo-technical.md`, runs scripts from the venv, and produces the
upstream report format (pass/fail per category, 0-100 score, prioritized
issues).

- [ ] **Step 4: DataForSEO smoke (in the same chat)**

Prompt: "Покажи топ-10 SERP по запиту 'cursor ide' через DataForSEO".
Verify `serp_organic_live_advanced` is called via `user-dataforseo`.

- [ ] **Step 5: Final commit + tag**

```bash
git add -A && git commit -m "chore: smoke-test fixes" --allow-empty
git tag v2.0.0-cursor.1 && git push origin main --tags
```

---

## Self-review (done at planning time)

- **Spec coverage:** design §3→Tasks 1-2, §4→Task 5, §5→Task 4, §6→Task 7, §7→Task 3, §8→Tasks 5-6/9, §9→Task 10, §10→Task 9, §11→Tasks 8/11, §12→commit steps throughout. No gaps.
- **Placeholders:** none; all new files have complete content (README/ATTRIBUTION/docs in Task 9 specified by exact structure and content requirements).
- **Consistency:** plugin name `cursor-seo`, venv path `.venv/`, rule file `cursor-seo-usage.mdc`, router `skills/cursor-seo-router/` used consistently across tasks.

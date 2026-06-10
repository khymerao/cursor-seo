# cursor-seo — Code Review Fix Plan

**Date:** 2026-06-10
**Reviewer findings:** see code review (agent 6859eca0)
**Strategy (model router: Reversibility → TRIZ → Via Negativa):** additive, marked
Cursor-override blocks only — never rewrite upstream logic. Every patch to a
vendored file uses an HTML comment marker `<!-- CURSOR-OVERRIDE: ... -->` so
`upstream-sync` can locate and re-apply it. Document each in ATTRIBUTION.

## Fixes

### Fix 1 (Important #1+#5 of review) — seo-dataforseo SKILL.md body
File: `skills/seo-dataforseo/SKILL.md`
- Wrap the upstream install block (lines ~36-44) in a Cursor-override note:
  replace the `./extensions/dataforseo/install.sh` guidance with: server is
  `user-dataforseo`, verify it in Settings → Tools & MCP, see
  `references/cursor-mcp-mapping.md`. Keep upstream text below a
  `<!-- CURSOR-OVERRIDE -->` marker, commented or clearly superseded.
- Patch Error Handling "MCP server not connected" (line ~395): replace
  "run `./extensions/dataforseo/install.sh`" with "connect/enable the
  `user-dataforseo` MCP server (Settings → Tools & MCP); see docs/mcp-setup.md".

### Fix 2 (Important #2) — tool-catalog.md header
File: `skills/seo-dataforseo/references/tool-catalog.md`
- Prepend a `<!-- CURSOR-OVERRIDE -->` header: in Cursor only the tools enabled
  in `user-dataforseo` (`ENABLED_MODULES`) are callable; full catalog below is
  the upstream reference; for the live Cursor mapping see
  `cursor-mcp-mapping.md`. Modules backlinks/onpage/content_analysis/
  business_data/ai_optimization are off by default.

### Fix 3 (Important #3) — inline-vs-parallel override
Files: `skills/seo-audit/SKILL.md`, `skills/seo/SKILL.md`
- Insert a `<!-- CURSOR-OVERRIDE -->` admonition right after frontmatter:
  "In the cursor-seo port, sub-agents run INLINE and SEQUENTIALLY. Ignore
  'parallel'/'up to 15 simultaneously' wording below; read each `agents/seo-*.md`
  and execute in the current context one at a time. See cursor-seo-router."

### Fix 4 (Important #4) — hook extension filter
File: `hooks/post-tool-use`
- Change the case filter from `*.html|*.json|*schema*.md|*SCHEMA*.md` to mirror
  `validate-schema.py` `valid_extensions`:
  `*.html|*.htm|*.jsx|*.tsx|*.vue|*.svelte|*.php|*.ejs`.

### Fix 5 (Minor) — mapping completeness
File: `skills/seo-dataforseo/references/cursor-mcp-mapping.md`
- Add the two utility tools to the enabled table: `dataforseo_labs_available_filters`,
  `kw_data_google_trends_categories`.

### Fix 6 (Minor) — advisory hook + rule name notes
Files: `docs/install.md`, `ATTRIBUTION.md`
- install.md: add a note that the schema hook is advisory (exit 0, injects
  context) not blocking, unlike upstream exit-code-2.
- ATTRIBUTION.md: record Fixes 1-5 as modifications; note rule is
  `cursor-seo-usage.mdc` (design doc said `-triggers`; plan/impl use `-usage`).

## Out of scope (Via Negativa — intentionally not "fixed")
- Hook non-blocking behavior (design choice; only documented).
- `validate.sh` `>=25` (sync-friendly; keep, add expected-count comment only).
- Missing `install-to-cursor.sh` (clone path documented in README).
- Release tag push (left to user; remote tag push was auto-review blocked).

## Verification
- `./setup/validate.sh` → VALIDATION PASSED
- `echo '{"file_path":"/tmp/x.tsx"}' | ./hooks/post-tool-use; echo exit=$?` → exit=0
- `python3 scripts/portability_check.py` → 0 errors
- grep confirms no remaining `extensions/dataforseo/install.sh` outside override markers

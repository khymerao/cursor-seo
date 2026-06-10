# Upstream sync procedure

How to merge new releases from [AgriciDaniel/claude-seo](https://github.com/AgriciDaniel/claude-seo)
into **cursor-seo** while preserving the thin Cursor adaptation layer.

**Current upstream pin:** tag `v2.0.0`, commit `dabfc1abb4ca9a4d7967242bf00d52593be56ed1`.

## Overview

```
fetch upstream tag
    → diff vendored trees
    → copy unchanged content
    → re-apply seo-dataforseo Prerequisites patch
    → validate + pytest subset
    → bump 2..0.0-cursor.N
    → commit + tag
```

## 1. Prepare upstream clone

```bash
git clone https://github.com/AgriciDaniel/claude-seo.git ~/work-porting/claude-seo
cd ~/work-porting/claude-seo
git fetch --tags
git checkout v2.0.0   # replace with new tag when syncing
git rev-parse HEAD    # record SHA for ATTRIBUTION.md
```

## 2. Diff vendored trees before copying

From the cursor-seo repo root:

```bash
cd ~/.cursor/plugins/local/cursor-seo
UP=~/work-porting/claude-seo

# Review changes skill-by-skill (repeat for each vendored tree)
git diff --no-index skills/seo-technical "$UP/skills/seo-technical" || true
git diff --no-index agents/ "$UP/agents/" || true
git diff --no-index scripts/ "$UP/scripts/" || true
```

Trees to sync (copy from upstream **into** cursor-seo):

| Vendored path | Copy command |
|---|---|
| `skills/` (25 `seo*` dirs only) | `rsync -a --delete "$UP/skills/seo" "$UP/skills/seo-"/ ./skills/` |
| `agents/` | `rsync -a --delete "$UP/agents/" ./agents/` |
| `scripts/` | `rsync -a --delete "$UP/scripts/" ./scripts/` |
| `data/` | `rsync -a --delete "$UP/data/" ./data/` |
| `schema/` | `rsync -a --delete "$UP/schema/" ./schema/` |
| `pdf/` | `rsync -a --delete "$UP/pdf/" ./pdf/` |
| `tests/` | `rsync -a --delete "$UP/tests/" ./tests/` |
| `hooks/validate-schema.py` | `cp "$UP/hooks/validate-schema.py" hooks/` |
| `requirements.txt` | `cp "$UP/requirements.txt" .` |
| `LICENSE` | `cp "$UP/LICENSE" .` |
| `docs/upstream/` | Refresh reference copies (see Task 2 list in port plan) |

**Do not overwrite** Cursor-only paths:

- `.cursor-plugin/`
- `skills/cursor-seo-router/`
- `rules/`
- `hooks/hooks.json`, `hooks/post-tool-use`
- `setup/`
- `README.md`, `ATTRIBUTION.md`, `docs/install.md`, `docs/mcp-setup.md`,
  `docs/porting-notes.md`, `docs/upstream-sync.md`
- `skills/seo-dataforseo/references/cursor-mcp-mapping.md`

**Do not restore** dropped upstream paths: `branding/`, `extensions/`, `.claude-plugin/`,
`install.sh`, `AGENTS.md`, etc.

## 3. Re-apply the seo-dataforseo patch

After copying skills, restore the **only intentional skill edit**:

In `skills/seo-dataforseo/SKILL.md`, the **Prerequisites** section must include the
Cursor port block **before** the upstream install.sh instructions:

```markdown
## Prerequisites

> **Cursor port:** the DataForSEO MCP server is configured in Cursor as
> `user-dataforseo` (Settings → Tools & MCP). Do NOT run
> `extensions/dataforseo/install.sh` — it targets Claude Code. Tool coverage
> and command mapping: `references/cursor-mcp-mapping.md`.
```

Update `references/cursor-mcp-mapping.md` if upstream adds new DataForSEO commands
or tool names change in the MCP server.

## 4. Update cursor-mcp-mapping (if needed)

Compare upstream `extensions/dataforseo/` docs (in upstream clone) against
`skills/seo-dataforseo/references/cursor-mcp-mapping.md`. Add rows for new commands;
note any tools that require optional `ENABLED_MODULES` ([mcp-setup.md](mcp-setup.md)).

## 5. Refresh router command map

If upstream adds slash commands or skills, update:

- `skills/cursor-seo-router/SKILL.md` — command table
- `rules/cursor-seo-usage.mdc` — trigger vocabulary (if new domains)

## 6. Run quality gates

```bash
cd ~/.cursor/plugins/local/cursor-seo

# Recreate venv if requirements.txt changed
./setup/setup.sh

# Structural validation (must pass)
./setup/validate.sh

# Upstream portability lint (must pass)
python3 scripts/portability_check.py

# Host-independent pytest subset
.venv/bin/python -m pytest tests/test_url_safety.py tests/test_schema_v2.py tests/test_portability.py -q
# Expected: 107 passed, 3 failed (AGENTS.md tests — file intentionally absent)
```

Optionally run full suite for awareness (many extension/marketplace failures expected):

```bash
.venv/bin/python -m pytest tests/ -q || true
```

Update [porting-notes.md](porting-notes.md) if the pytest baseline changes.

## 7. Bump Cursor version

Edit `.cursor-plugin/plugin.json`:

```json
"version": "2.0.0-cursor.N"
```

Increment **N** for each Cursor-port release after an upstream merge (e.g.
`2.0.0-cursor.1` → `2.0.0-cursor.2`). Optionally mirror in
`skills/cursor-seo-router/SKILL.md` metadata.

## 8. Update attribution

Edit [ATTRIBUTION.md](../ATTRIBUTION.md):

- New upstream tag and commit SHA
- Note any newly modified files (should still be **only** seo-dataforseo Prerequisites
  unless the port layer intentionally changed)

## 9. Commit and tag

```bash
git add -A
git commit -m "chore: sync upstream claude-seo vX.Y.Z (SHA) — cursor.N"
git tag vX.Y.Z-cursor.N
git push origin main --tags
```

## Checklist

- [ ] Upstream tag checked out; SHA recorded
- [ ] Vendored trees diffed and copied
- [ ] seo-dataforseo Prerequisites patch re-applied
- [ ] cursor-mcp-mapping.md updated (if DataForSEO changed)
- [ ] Router updated (if new commands/skills)
- [ ] `./setup/validate.sh` passes
- [ ] `portability_check.py` passes
- [ ] Pytest subset 107/110 (3 AGENTS.md failures OK)
- [ ] `version` bumped to `X.Y.Z-cursor.N`
- [ ] ATTRIBUTION.md updated
- [ ] Tag pushed

## When upstream is a major version

Read upstream `docs/MIGRATION-*.md` (if present) before merging. Major releases may:

- Rename skills or commands → update router + porting-notes
- Change script interfaces → rerun smoke tests ([install.md](install.md))
- Add extensions → decide per design §2 (core + DataForSEO only in v1 port policy)

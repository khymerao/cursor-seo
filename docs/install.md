# Install guide

Install **cursor-seo** as a Cursor local plugin at `~/.cursor/plugins/local/cursor-seo`.

## Prerequisites

- [Cursor](https://cursor.com) with local plugins enabled
- **Python 3.10+** on your PATH (or set `PYTHON=` explicitly — see below)
- **Git**
- **Optional:** Node.js 20+ for the DataForSEO MCP server ([mcp-setup.md](mcp-setup.md))

## Quick install

```bash
git clone https://github.com/khymerao/cursor-seo.git ~/.cursor/plugins/local/cursor-seo
cd ~/.cursor/plugins/local/cursor-seo
./setup/setup.sh
```

Reload Cursor: **Cmd+Shift+P → Developer: Reload Window** (or **Reload Window**).

Verify:

```bash
./setup/validate.sh
```

Expected last line: `VALIDATION PASSED`.

## Python version

`setup/setup.sh` requires Python **3.10 or newer**. On macOS, system `python3` may be 3.9.

Check:

```bash
python3 --version
```

If older than 3.10, install Python 3.12 (Homebrew, pyenv, or python.org) and run:

```bash
PYTHON=python3.12 ./setup/setup.sh
```

You can export `PYTHON=python3.12` in your shell profile for repeat runs.

## Setup flags

```bash
./setup/setup.sh                  # core dependencies only
./setup/setup.sh --with-render    # + Playwright Chromium (SPA / JS rendering)
./setup/setup.sh --with-pdf       # + WeasyPrint, matplotlib, openpyxl (PDF/Excel reports)
./setup/setup.sh --with-render --with-pdf
```

| Flag | Installs | Used by |
|---|---|---|
| *(none)* | Core `requirements.txt` minus heavy extras | Most scripts, schema, audits |
| `--with-render` | Playwright + Chromium | `scripts/render_page.py`, agents that need rendered DOM |
| `--with-pdf` | WeasyPrint, matplotlib, openpyxl | PDF audit reports, chart exports |

Skills degrade gracefully without optional extras: raw HTML fetch instead of rendered pages;
markdown reports instead of PDF.

## What setup creates

```
~/.cursor/plugins/local/cursor-seo/
├── .venv/              # Plugin Python environment
├── .cursor-plugin/     # Cursor manifest
├── skills/             # 25 seo* skills + cursor-seo-router
├── agents/             # 18 inline agent prompts
├── hooks/              # postToolUse schema validation
└── scripts/            # Analysis scripts (run via .venv/bin/python)
```

## Schema validation hook (advisory)

The `post-tool-use` hook runs `validate-schema.py` after edits to schema-bearing
files (HTML, JSX/TSX, Vue, Svelte, PHP, EJS, etc.). In this Cursor port the hook
is **advisory**: it always exits `0` and injects `additional_context` for the
agent — it does **not** block edits. Upstream Claude Code used exit code `2` to
block invalid schema writes.

## Post-install checks in Cursor

After Reload Window, confirm in Cursor Settings:

1. **Plugins** — `cursor-seo` appears with version `2.0.0-cursor.*`
2. **Rules → Agent Decides** — SEO skills listed (including `cursor-seo-router`)
3. **Hooks** — `post-tool-use` registered for the plugin

Trigger a smoke prompt:

> «Швидкий технічний SEO-чек https://example.com»

The agent should load `cursor-seo-router` → `seo-technical` and run scripts from `.venv`.

## DataForSEO (optional)

Live SERP/keyword data requires a separate MCP server — not installed by `setup.sh`.

→ [mcp-setup.md](mcp-setup.md)

## Troubleshooting

### `ERROR: Python 3.10+ required`

Install a newer Python and rerun with `PYTHON=python3.12 ./setup/setup.sh`.

### `.venv` missing or scripts fail with `ModuleNotFoundError`

```bash
cd ~/.cursor/plugins/local/cursor-seo
rm -rf .venv
./setup/setup.sh
```

Re-run with `--with-render` / `--with-pdf` if those features are needed.

### `./setup/validate.sh` fails

Read the `ERROR:` lines. Common causes:

- Incomplete clone — rerun `git pull`
- Missing executable bit on hooks: `chmod +x hooks/post-tool-use setup/*.sh`
- Skill count mismatch — ensure `skills/` has 25 `seo*` directories plus router

### Hook not firing after schema edits

1. Reload Window after install or hook changes
2. Cursor **Settings → Hooks** — confirm cursor-seo hook is enabled
3. Hook only runs on schema-relevant files (`*.html`, `*.htm`, `*.jsx`, `*.tsx`, `*.vue`, `*.svelte`, `*.php`, `*.ejs`)
4. If blocking is unreliable, manually run:
   ```bash
   .venv/bin/python hooks/validate-schema.py path/to/file.json
   ```

### Plugin skills not appearing

- Path must be exactly `~/.cursor/plugins/local/cursor-seo`
- Reload Window after clone or git pull
- Check `.cursor-plugin/plugin.json` is valid JSON

### Playwright / render errors

```bash
./setup/setup.sh --with-render
# or manually:
.venv/bin/playwright install chromium
```

### Replacing seo-geo-cursor

If you previously used seo-geo-cursor, disable it before relying on cursor-seo:

```bash
mv ~/.cursor/plugins/local/seo-geo-cursor ~/.cursor/plugins/_archive-seo-geo-cursor
```

Reload Window. See [porting-notes.md](porting-notes.md) for feature mapping.

## Uninstall

```bash
rm -rf ~/.cursor/plugins/local/cursor-seo
```

Reload Window. Credentials in `~/.config/claude-seo/` and drift DB in `~/.cache/claude-seo/`
are left intact (user data).

## Next steps

- [README.md](../README.md) — usage examples
- [porting-notes.md](porting-notes.md) — Claude → Cursor differences
- [mcp-setup.md](mcp-setup.md) — live DataForSEO data
- [upstream-sync.md](upstream-sync.md) — updating from upstream releases

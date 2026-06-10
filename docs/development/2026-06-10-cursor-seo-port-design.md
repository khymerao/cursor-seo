# cursor-seo — Design: Porting claude-seo v2.0.0 to a Cursor Local Plugin

**Date:** 2026-06-10
**Status:** Approved
**Upstream:** [AgriciDaniel/claude-seo](https://github.com/AgriciDaniel/claude-seo) v2.0.0 (MIT)
**Boilerplate:** [khymerao/cursor-plugin](https://github.com/khymerao/cursor-plugin)
**Supersedes:** [khymerao/seo-geo-cursor](https://github.com/khymerao/seo-geo-cursor) (to be disabled/archived)

## 1. Goal

Port the claude-seo plugin (25 sub-skills, 18 sub-agents, ~50 Python scripts,
hooks, DataForSEO extension) from Claude Code to a Cursor local plugin named
`cursor-seo`, installed at `~/.cursor/plugins/local/cursor-seo` and published
to `khymerao/cursor-seo`.

## 2. Decisions (locked)

| Decision | Choice |
|---|---|
| Relation to existing seo-geo-cursor | **Replace** — disable/uninstall old plugin, archive its repo with "superseded by cursor-seo" note |
| Scope of v1 port | **Core + DataForSEO**: all 25 skills, 18 agents, scripts, hooks, router. Other 7 extensions (Firecrawl, Banana, Ahrefs, SE Ranking, Profound, Bing Webmaster, Unlighthouse) documented as optional, not patched |
| Sub-agent execution | **Inline, sequential** — no Task-tool parallel dispatch. `agents/*.md` stay vendored; the router instructs the agent to read the agent file and execute its instructions in the current context, ignoring Claude frontmatter (`model`, `maxTurns`, `tools`) |
| Porting strategy | **Vendored upstream + thin Cursor layer** (approach A) — upstream content unchanged where possible; Cursor adaptations live in new files or minimal patches |
| Plugin / repo name | `cursor-seo` / `khymerao/cursor-seo` |
| Models for the port work | Planning/review with strong models; mechanical code writing delegated to Composer 2.5 subagents |

## 3. Repository structure

```
cursor-seo/                          # = ~/.cursor/plugins/local/cursor-seo
├── .cursor-plugin/plugin.json       # NEW: Cursor manifest (name, skills, rules, hooks paths)
├── skills/                          # VENDORED: 25 upstream skills as-is
│   ├── seo/ … seo-technical/ … seo-dataforseo/ …
│   └── cursor-seo-router/           # NEW: router skill (single entry point)
├── agents/                          # VENDORED: 18 agent prompt files, unchanged
├── scripts/                         # VENDORED: ~50 Python scripts, unchanged
├── data/                            # VENDORED: google-updates.json
├── schema/                          # VENDORED: templates.json
├── pdf/                             # VENDORED: google-seo-reference.md
├── hooks/
│   ├── hooks.json                   # NEW: Cursor hook format
│   └── validate-schema.py           # VENDORED
├── rules/cursor-seo-triggers.mdc    # NEW: agent-requestable trigger rule
├── setup/                           # NEW: setup.sh, install-to-cursor.sh, validate.sh (boilerplate-derived)
├── requirements.txt                 # VENDORED
├── tests/                           # VENDORED subset that runs without a Claude host
├── docs/                            # NEW Cursor docs + docs/upstream/ (original docs as reference)
├── ATTRIBUTION.md                   # NEW: full list of modifications over upstream
└── LICENSE                          # MIT (upstream license preserved)
```

**Dropped from upstream:** `branding/`, `screenshots/`, `assets/diagrams/`,
`.devcontainer/`, upstream `.github/`, `install.sh|.ps1`, `uninstall.*`,
`.claude-plugin/marketplace.json`, and 7 of 8 `extensions/` (kept: dataforseo
content merged into the patched core skill + docs).

## 4. Router skill (replaces `/seo` slash commands)

`skills/cursor-seo-router/SKILL.md` maps the 27 upstream commands to natural
language. Cursor has no command palette for plugins; the router + trigger rule
replace `commandNamespace`.

| Upstream command | Router behavior |
|---|---|
| `/seo audit <url>` | Orchestrator `skills/seo` + inline agents, fixed sequence: technical → content → schema → geo → local (if relevant) → synthesis via 10-principle framework |
| `/seo page`, `/seo technical`, `/seo content`, `/seo schema`, `/seo geo`, … | Direct dispatch to the matching `skills/seo-*` skill |
| `/seo dataforseo <cmd>` | `skills/seo-dataforseo` → existing `user-dataforseo` MCP server (MCP-first) |
| `/seo google setup` | `skills/seo-google` credential wizard; credentials stay at `~/.config/claude-seo/` (scripts hardcode this path — do not change) |
| `/seo maps`, `/seo drift`, `/seo cluster`, `/seo flow`, … | Direct skill dispatch |

**Inline agent contract** (stated in the router): "Read `agents/seo-<name>.md`,
follow its body instructions in the current context. Ignore frontmatter keys
`model`, `maxTurns`, `tools` — they are Claude Code specific. Execute agents
sequentially; do not spawn parallel subagents."

## 5. Hooks

| Upstream (Claude) | Cursor port |
|---|---|
| `PostToolUse` matcher `Edit\|Write` → `validate-schema.py "$FILE_PATH"` | `postToolUse` in `hooks/hooks.json`; command uses `${CURSOR_PLUGIN_ROOT}` and the plugin venv python |
| SessionStart / Stop | Not present upstream — not added (via negativa) |

## 6. MCP / DataForSEO

- The plugin ships **no MCP server of its own** (unlike seo-geo-cursor). Core
  claude-seo is zero-network; live data comes from the user's existing
  `user-dataforseo` MCP server.
- Patch `skills/seo-dataforseo/SKILL.md` + `references/tool-catalog.md`:
  MCP-first usage instead of `extensions/dataforseo/install.sh`; map the 22
  upstream commands to `user-dataforseo` tools; keep upstream cost guardrails
  (`references/cost-tiers.md`) intact.
- `docs/mcp-setup.md` documents DataForSEO MCP setup for fresh installs.

## 7. Python runtime

- `setup/setup.sh` creates `.venv` at the plugin root and installs
  `requirements.txt`.
- Optional flags: `--with-render` (Playwright Chromium for SPA rendering),
  `--with-pdf` (WeasyPrint/matplotlib for PDF reports). Skills already degrade
  gracefully (raw HTML fetch / markdown report) without them.
- Script invocation convention documented in the router:
  `"$CURSOR_PLUGIN_ROOT/.venv/bin/python" scripts/<name>.py`.

## 8. Superpowers coexistence

Same proven pattern as the seo-geo-cursor port:

| Situation | Use |
|---|---|
| SEO deliverable (audit, report, schema, keywords) | `cursor-seo-router` directly — **no brainstorming gate** |
| Building code from SEO findings (theme module, automation) | Superpowers `brainstorming` → `writing-plans` first |
| Debugging / tests for SEO code | Superpowers `systematic-debugging`, `test-driven-development` |

Boundaries are stated in the router skill and `docs/porting-notes.md`. No hook
conflicts: cursor-seo registers only `postToolUse`.

## 9. Replacement of seo-geo-cursor

1. Disable/remove `~/.cursor/plugins/local/seo-geo-cursor` (and its
   `seo-geo-triggers.mdc` rule).
2. Archive `khymerao/seo-geo-cursor` on GitHub with a "superseded by
   cursor-seo" note in the README.
3. `rules/cursor-seo-triggers.mdc` takes over the same trigger vocabulary
   (SEO, GEO, schema, audit, keywords, rankings, AI visibility…).
4. `memory/hot-cache.md` in user projects is project data and remains usable.

## 10. Documentation

- `README.md` — Cursor-first: install, example prompts replacing `/seo`
  commands, capability table, requirements.
- `docs/porting-notes.md` — Claude → Cursor compatibility matrix (section 4–7
  of this design, expanded).
- `docs/install.md`, `docs/mcp-setup.md`, `docs/upstream-sync.md` (how to merge
  AgriciDaniel releases).
- `docs/upstream/` — original ARCHITECTURE.md, COMMANDS.md, README.md kept as
  reference.
- `ATTRIBUTION.md` — MIT attribution + complete list of added/modified files.

## 11. Quality gates

1. `python scripts/portability_check.py` passes on vendored skills.
2. `setup/validate.sh` — manifest consistency (every path in `plugin.json`
   exists; router/rules/hooks well-formed JSON/YAML).
3. Vendored pytest subset that doesn't require a Claude host (schema,
   url_safety, render_page, portability).
4. Live smoke test: router-driven mini-audit of example.com + 2–3 scripts
   executed from the venv; DataForSEO MCP ping.

## 12. Delivery process

- Conventional commits per phase: scaffold → vendor → router → hooks →
  DataForSEO patch → docs → validation. Push to `khymerao/cursor-seo`
  throughout.
- Mechanical code writing delegated to Composer 2.5 subagents; planning and
  review in the main session.

## 13. Error handling & edge cases

- **Missing venv / deps:** router tells the agent to run `setup/setup.sh`
  before script-backed flows; zero-dependency skills still work.
- **No DataForSEO MCP:** `seo-dataforseo` skill documents paste-data fallback
  and points to `docs/mcp-setup.md`; core audits are unaffected.
- **Hook blocking unreliability:** as in the previous port, skills document
  manual artifact checks if `postToolUse` exit-code blocking is flaky.
- **Upstream Claude-isms in skill bodies** (e.g. `/seo google setup` text):
  not rewritten; the router maps the phrasing, `porting-notes.md` records the
  mapping for users.

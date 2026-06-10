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

# 3. Counts: upstream seo* skills + router, 18 agents
S=$(ls -d "$ROOT"/skills/seo*/ 2>/dev/null | wc -l | tr -d ' ')
[[ "$S" -ge "25" ]] && ok "$S upstream seo* skills (expected >=25)" || fail "expected >=25 seo* skills, got $S"
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

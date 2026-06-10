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

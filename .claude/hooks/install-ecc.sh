#!/bin/bash
# Install the ECC plugin (github.com/affaan-m/ECC) and its npm runtime
# dependencies. Runs at every session start and does nothing when ECC is
# already in place. Never fails the session.
set -uo pipefail

command -v claude >/dev/null 2>&1 || exit 0

plugins_dir="${CLAUDE_CONFIG_DIR:-$HOME/.claude}/plugins"

# Cloud sessions do not install plugins declared in .claude/settings.json.
if ! grep -q '"ecc@ecc"' "$plugins_dir/installed_plugins.json" 2>/dev/null; then
  claude plugin marketplace add affaan-m/ECC </dev/null >/dev/null 2>&1
  claude plugin install ecc@ecc -y </dev/null >/dev/null 2>&1
fi

# Claude Code's plugin installer skips ECC's npm dependencies, which breaks
# ECC's own SessionStart hook ("Cannot find module 'js-yaml'") after every
# install or update.
if command -v npm >/dev/null 2>&1; then
  for d in "$plugins_dir"/cache/ecc/ecc/*/; do
    [ -d "$d" ] || continue
    [ -d "${d}node_modules/js-yaml" ] && continue
    (cd "$d" && npm install --omit=dev --no-audit --no-fund --ignore-scripts >/dev/null 2>&1)
  done
fi

exit 0

#!/usr/bin/env bash
# Runs the SPIKE, not PlutoDeck.
#
# To present a deck, use `mise run deck` from the repository root. That path needs no Node
# and is what issues 004-006 replaced this with.
#
# What this still earns its place for is /ui-probe.html, the rendering proof behind issue 009
# and the working reference `spec/START-HERE.md` points at: the <pluto-cell> wrapper, the Set
# for PlutoJSInitializingContext, and change-driven repainting.
#
# Boots the Pluto backend and the Node bridge together. Ctrl-C stops both.
set -euo pipefail
cd "$(dirname "$0")"

JULIA_CHANNEL="${PLUTE_JULIA_CHANNEL:-dyad-3.3.0}"   # matches .vscode/settings.json
UI_PORT="${PLUTE_UI_PORT:-8099}"

rm -f backend/.session
echo "[start] julia +${JULIA_CHANNEL}  (first run installs Pluto — this takes a minute)"
julia "+${JULIA_CHANNEL}" --project=backend backend/server.jl &
PLUTO_PID=$!
trap 'kill $PLUTO_PID 2>/dev/null || true' EXIT INT TERM

PLUTE_UI_PORT="$UI_PORT" node bridge/orchestrator.mjs

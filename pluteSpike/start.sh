#!/usr/bin/env bash
# Boots the Pluto backend and the deck bridge together. Ctrl-C stops both.
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

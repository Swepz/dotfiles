#!/usr/bin/env bash
set -euo pipefail

LOG_DIR="$HOME/.cache/ashell"
mkdir -p "$LOG_DIR"

CONFIG_RENDER="${ASHELL_CONFIG_RENDER:-$HOME/.config/ashell/render-config.sh}"
CONFIG_PATH="${ASHELL_RUNTIME_CONFIG:-${XDG_CACHE_HOME:-$HOME/.cache}/ashell/config.toml}"

"$CONFIG_RENDER"

pkill -x ashell 2>/dev/null || true
sleep 0.2

if command -v hyprctl >/dev/null 2>&1 && hyprctl monitors >/dev/null 2>&1; then
    hyprctl dispatch exec "ashell --config-path $CONFIG_PATH" >>"$LOG_DIR/ashell.log" 2>&1
else
    nohup ashell --config-path "$CONFIG_PATH" >>"$LOG_DIR/ashell.log" 2>&1 </dev/null &
fi

#!/usr/bin/env bash
set -euo pipefail

LOG_DIR="$HOME/.cache/ashell"
mkdir -p "$LOG_DIR"

CONFIG_RENDER="${ASHELL_CONFIG_RENDER:-$HOME/.config/ashell/render-config.sh}"
CONFIG_PATH="${ASHELL_RUNTIME_CONFIG:-${XDG_CACHE_HOME:-$HOME/.cache}/ashell/config.toml}"

# AShell's wgpu Vulkan backend renders a transparent layer on the hybrid
# Intel/NVIDIA setup. Prefer GLES while allowing an explicit override.
export WGPU_BACKEND="${WGPU_BACKEND:-gl}"

"$CONFIG_RENDER"

pkill -x ashell 2>/dev/null || true
sleep 0.2

if command -v hyprctl >/dev/null 2>&1 && hyprctl monitors >/dev/null 2>&1; then
    hyprctl dispatch "hl.dsp.exec_cmd([[env WGPU_BACKEND=$WGPU_BACKEND ashell --config-path $CONFIG_PATH]])" >>"$LOG_DIR/ashell.log" 2>&1
else
    nohup ashell --config-path "$CONFIG_PATH" >>"$LOG_DIR/ashell.log" 2>&1 </dev/null &
fi

#!/usr/bin/env bash
set -euo pipefail

enabled_file="$XDG_RUNTIME_DIR/hypr-gamemode"

if [ -f "$enabled_file" ]; then
    hyprctl reload
    rm "$enabled_file"
    notify-send "Gamemode deactivated" "Display effects restored"
else
    hyprctl eval 'hl.config({ animations = { enabled = false }, decoration = { shadow = { enabled = false }, blur = { enabled = false }, rounding = 0 }, general = { gaps_in = 0, gaps_out = 0, border_size = 1 } })'
    touch "$enabled_file"
    notify-send "Gamemode activated" "Display effects disabled"
fi

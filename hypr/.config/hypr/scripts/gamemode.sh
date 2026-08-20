#!/usr/bin/env bash
set -euo pipefail

cache_folder="$HOME/.cache/hyprland-wallpapers"
enabled_file="$cache_folder/gamemode_enabled"
restart_file="$cache_folder/restart-wpauto"
automation_file="$cache_folder/wallpaper-automation"
automation="$HOME/.config/hypr/scripts/wallpaper-automation.sh"

mkdir -p "$cache_folder"

if [ -f "$enabled_file" ]; then
    if [ -f "$restart_file" ]; then
        rm "$restart_file"
        "$automation" &
    fi
    hyprctl reload
    rm "$enabled_file"
    notify-send "Gamemode deactivated" "Display effects restored"
else
    if [ -f "$automation_file" ]; then
        touch "$restart_file"
        rm "$automation_file"
        pkill -f -- "$automation"
    fi
    hyprctl eval 'hl.config({ animations = { enabled = false }, decoration = { shadow = { enabled = false }, blur = { enabled = false }, rounding = 0 }, general = { gaps_in = 0, gaps_out = 0, border_size = 1 } })'
    touch "$enabled_file"
    notify-send "Gamemode activated" "Display effects disabled"
fi

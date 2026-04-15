#!/usr/bin/env bash

# -----------------------------------------------------
# Load Launcher
# -----------------------------------------------------
launcher=$(cat $HOME/.config/hypr/settings/launcher 2>/dev/null || echo "rofi")

# Use Walker
_launch_walker() {
    $HOME/.config/walker/launch.sh --height 500
}

# Use Rofi
_launch_rofi() {
    pkill rofi || rofi -show drun -replace -i -config ~/.config/rofi/config-compact.rasi
}

if [ "$launcher" == "walker" ]; then
    _launch_walker
else
    _launch_rofi
fi

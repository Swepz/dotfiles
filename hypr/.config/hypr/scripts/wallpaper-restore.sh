#!/usr/bin/env bash
#                _ _
# __      ____ _| | |_ __   __ _ _ __   ___ _ __
# \ \ /\ / / _` | | | '_ \ / _` | '_ \ / _ \ '__|
#  \ V  V / (_| | | | |_) | (_| | |_) |  __/ |
#   \_/\_/ \__,_|_|_| .__/ \__,_| .__/ \___|_|
#                   |_|         |_|
#
# -----------------------------------------------------
# Restore last wallpaper
# -----------------------------------------------------

# -----------------------------------------------------
# Set defaults
# -----------------------------------------------------

cache_folder="$HOME/.cache/hyprland-wallpapers"
mkdir -p "$cache_folder"

defaultwallpaper="$HOME/.config/hypr/wallpapers/default.jpg"

cachefile="$cache_folder/current_wallpaper"

# -----------------------------------------------------
# Get current wallpaper
# -----------------------------------------------------

if [ -f "$cachefile" ]; then
    sed -i "s|~|$HOME|g" "$cachefile"
    wallpaper=$(cat $cachefile)
    if [ -f $wallpaper ]; then
        echo ":: Wallpaper $wallpaper exists"
    else
        echo ":: Wallpaper $wallpaper does not exist. Using default."
        wallpaper=$defaultwallpaper
    fi
else
    echo ":: $cachefile does not exist. Using default wallpaper."
    wallpaper=$defaultwallpaper
fi

# -----------------------------------------------------
# Set wallpaper with hyprpaper
# -----------------------------------------------------

echo ":: Setting wallpaper with source image $wallpaper"

# Start hyprpaper if not running
if ! pgrep -x "hyprpaper" > /dev/null; then
    hyprpaper &
    sleep 0.5
fi

# Set wallpaper via hyprctl
hyprctl hyprpaper wallpaper ",$wallpaper"

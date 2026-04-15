#!/usr/bin/env bash
#  _____                 _       __        __          _
# |_   _|__   __ _  __ _| | ___  \ \      / /_ _ _   _| |__   __ _ _ __
#   | |/ _ \ / _` |/ _` | |/ _ \  \ \ /\ / / _` | | | | '_ \ / _` | '__|
#   | | (_) | (_| | (_| | |  __/   \ V  V / (_| | |_| | |_) | (_| | |
#   |_|\___/ \__, |\__, |_|\___|    \_/\_/ \__,_|\__, |_.__/ \__,_|_|
#            |___/ |___/                         |___/
#

if [ -f $HOME/.cache/hyprland-wallpapers/waybar_disabled ]; then
    rm $HOME/.cache/hyprland-wallpapers/waybar_disabled
else
    touch $HOME/.cache/hyprland-wallpapers/waybar_disabled
fi
$HOME/.config/waybar/launch.sh &

#!/usr/bin/env bash
set -euo pipefail

rofi_config="${ROFI_CONFIG:-$HOME/.config/rofi/config-power.rasi}"
power_script="$HOME/.config/hypr/scripts/power.sh"

choose() {
    printf '%s\n' "Lock" "Suspend" "Log Out" "Restart" "Power Off" |
        rofi -dmenu -i -replace -p "Power" -config "$rofi_config"
}

confirm() {
    local prompt="$1"
    local answer

    answer=$(printf '%s\n' "No" "Yes" |
        rofi -dmenu -i -replace -p "$prompt" -config "$rofi_config")

    [[ "$answer" == "Yes" ]]
}

choice="$(choose)"

case "$choice" in
    "Lock")
        exec "$power_script" lock
        ;;
    "Suspend")
        exec "$power_script" suspend
        ;;
    "Log Out")
        confirm "Log out?" && exec "$power_script" exit
        ;;
    "Restart")
        confirm "Restart?" && exec "$power_script" reboot
        ;;
    "Power Off")
        confirm "Power off?" && exec "$power_script" shutdown
        ;;
esac

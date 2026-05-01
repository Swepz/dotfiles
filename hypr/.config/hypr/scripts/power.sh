#!/usr/bin/env bash
set -euo pipefail

require_hyprshutdown() {
    if command -v hyprshutdown >/dev/null 2>&1; then
        return 0
    fi

    notify-send "Power action unavailable" "hyprshutdown is not installed"
    exit 1
}

case "${1:-}" in
    lock)
        playerctl --all-players pause >/dev/null 2>&1 || true
        pidof hyprlock >/dev/null 2>&1 || exec hyprlock
        ;;
    suspend)
        exec systemctl suspend
        ;;
    exit)
        require_hyprshutdown
        exec hyprshutdown -t "Logging out..."
        ;;
    reboot)
        require_hyprshutdown
        exec hyprshutdown -t "Restarting..." --post-cmd "systemctl reboot"
        ;;
    shutdown)
        require_hyprshutdown
        exec hyprshutdown -t "Powering off..." --post-cmd "systemctl poweroff"
        ;;
    hibernate)
        exec systemctl hibernate
        ;;
    *)
        printf 'Usage: %s {lock|suspend|exit|reboot|shutdown|hibernate}\n' "$0" >&2
        exit 2
        ;;
esac

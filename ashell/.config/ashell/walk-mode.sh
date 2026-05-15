#!/usr/bin/env bash
set -euo pipefail

service="${CLAMSHELL_WALK_MODE_SERVICE:-clamshell-walk-mode.service}"

case "${1:-status}" in
    status)
        systemctl --user is-active --quiet "$service"
        ;;
    start)
        systemctl --user start "$service"
        ;;
    stop)
        systemctl --user stop "$service"
        ;;
    toggle)
        if systemctl --user is-active --quiet "$service"; then
            systemctl --user stop "$service"
        else
            systemctl --user start "$service"
        fi
        ;;
    *)
        printf 'Usage: %s {status|start|stop|toggle}\n' "$0" >&2
        exit 64
        ;;
esac

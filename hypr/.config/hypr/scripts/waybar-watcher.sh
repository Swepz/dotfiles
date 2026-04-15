#!/usr/bin/env bash
# Restart waybar after a Hyprland monitor is REMOVED.
#
# Why: Waybar destroys its per-output bar surface and all modules attached to
# it when an output is removed. D-Bus-backed modules (power-profiles-daemon,
# idle-inhibitor, bluetooth, network) lose their connections and stop
# updating. Tracked upstream as Alexays/Waybar#4823 — no fix yet. The only
# reliable workaround is to bounce waybar after the surface was destroyed so
# modules rebuild from scratch.
#
# We deliberately do NOT react to:
#   monitoraddedv2    - waybar natively attaches a new bar when an output
#                       appears; killing it at that moment races with the
#                       native attach and causes visible flicker.
#   configreloaded    - HDM calls hyprctl reload after swapping monitors.conf;
#                       if that reload actually removed a monitor, we'll
#                       catch it via monitorremovedv2 a few ms later. Reacting
#                       to configreloaded on top adds a redundant kill-respawn
#                       cycle for every lid/hotplug transition.

set -euo pipefail

SOCKET="$XDG_RUNTIME_DIR/hypr/${HYPRLAND_INSTANCE_SIGNATURE:-}/.socket2.sock"

if [ -z "${HYPRLAND_INSTANCE_SIGNATURE:-}" ] || [ ! -S "$SOCKET" ]; then
    echo "waybar-watcher: HYPRLAND_INSTANCE_SIGNATURE unset or socket missing" >&2
    exit 1
fi

command -v socat >/dev/null || {
    echo "waybar-watcher: socat not installed" >&2
    exit 1
}

exec socat -U - "UNIX-CONNECT:$SOCKET" | while IFS= read -r line; do
    case "${line%%>>*}" in
        monitorremovedv2)
            ~/.config/waybar/launch.sh
            ;;
    esac
done

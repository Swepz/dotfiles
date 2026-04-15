#!/usr/bin/env bash
# Waybar launcher + watchdog.
#
# - First invocation starts a background supervisor that keeps waybar alive.
# - Subsequent invocations (Mod+Shift+B, waypaper post-command, manual) fall
#   through to a single killall; the existing supervisor respawns waybar with
#   the refreshed config.
# - Respects $DISABLE_FLAG for toggle.sh.
# - Crash-loop detector: 5 consecutive <5s exits -> notify + give up.

LOCK=/tmp/waybar-launch.lock
DISABLE_FLAG=$HOME/.cache/hyprland-wallpapers/waybar_disabled

(
    exec 200>"$LOCK"
    if ! flock -n 200; then
        # Supervisor already running. Kick waybar; supervisor respawns it.
        killall waybar 2>/dev/null
        exit 0
    fi

    # We are the supervisor. Clean up any stale waybar from a previous session.
    killall waybar 2>/dev/null
    sleep 0.3

    fails=0
    while true; do
        if [ -f "$DISABLE_FLAG" ]; then
            sleep 1
            continue
        fi

        start=$(date +%s)
        waybar -c "$HOME/.config/waybar/config" -s "$HOME/.config/waybar/style.css"
        elapsed=$(( $(date +%s) - start ))

        if [ "$elapsed" -lt 5 ]; then
            fails=$(( fails + 1 ))
            if [ "$fails" -ge 5 ]; then
                notify-send -u critical "Waybar watchdog" \
                    "5 consecutive fast exits. Giving up. Run ~/.config/waybar/launch.sh manually after fixing."
                exit 1
            fi
            sleep 2
        else
            fails=0
        fi
    done
) &
disown

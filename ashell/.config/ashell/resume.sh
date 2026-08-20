#!/usr/bin/env bash
set -euo pipefail

HYPRCTL="${HYPRCTL:-hyprctl}"
SOCAT="${SOCAT:-socat}"
JQ="${JQ:-jq}"
LAUNCH="${ASHELL_LAUNCH:-$HOME/.config/ashell/launch.sh}"
EVENT_TIMEOUT="${ASHELL_RESUME_EVENT_TIMEOUT:-8s}"
LOG_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/ashell"
LOG_FILE="$LOG_DIR/resume.log"

mkdir -p "$LOG_DIR"

log() {
    printf '%s %s\n' "$(date --iso-8601=seconds)" "$*" >>"$LOG_FILE"
}

monitor_ready() {
    "$HYPRCTL" monitors -j 2>>"$LOG_FILE" |
        "$JQ" -e 'any(.[]; ((.disabled // false) | not) and (.dpmsStatus // true))' >/dev/null
}

launch_ashell() {
    log "launching ashell after Hyprland output readiness"
    "$LAUNCH"
}

"$HYPRCTL" dispatch 'hl.dsp.dpms({ action = "enable" })' >>"$LOG_FILE" 2>&1

if monitor_ready; then
    launch_ashell
    exit 0
fi

SOCKET="$XDG_RUNTIME_DIR/hypr/${HYPRLAND_INSTANCE_SIGNATURE:-}/.socket2.sock"

if [ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ] && command -v "$SOCAT" >/dev/null 2>&1; then
    while IFS= read -r line; do
        case "${line%%>>*}" in
            monitoraddedv2|focusedmonv2|configreloaded)
                if monitor_ready; then
                    launch_ashell
                    exit 0
                fi
                ;;
        esac
    done < <(timeout "$EVENT_TIMEOUT" "$SOCAT" -U - "UNIX-CONNECT:$SOCKET" 2>>"$LOG_FILE" || true)
else
    log "Hyprland socket event prerequisites missing"
fi

if monitor_ready; then
    launch_ashell
    exit 0
fi

log "ashell restart skipped: no ready Hyprland output observed"
exit 1

#!/usr/bin/env bash
set -euo pipefail

PIDFILE=/tmp/gpu-screen-recorder.pid
STATEFILE=/tmp/gpu-screen-recorder.status

emit_state() {
    if [[ -f "$PIDFILE" ]] && kill -0 "$(cat "$PIDFILE")" 2>/dev/null; then
        printf '{"text":"REC","alt":"recording"}\n'
    else
        printf '{"text":"","alt":"idle"}\n'
    fi
}

touch "$STATEFILE"
emit_state

tail -n 0 -F "$STATEFILE" 2>/dev/null | while IFS= read -r _; do
    emit_state
done

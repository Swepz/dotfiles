#!/usr/bin/env bash
set -euo pipefail

base_config="${ASHELL_BASE_CONFIG:-$HOME/.config/ashell/config.toml}"
runtime_config="${ASHELL_RUNTIME_CONFIG:-${XDG_CACHE_HOME:-$HOME/.cache}/ashell/config.toml}"
pidfile="${RECORDING_PIDFILE:-/tmp/gpu-screen-recorder.pid}"
idle_modules='right = [["MediaPlayer", "Tray", "SystemInfo", "Tempo", "Privacy", "Settings"]]'
recording_modules='right = [["MediaPlayer", "Tray", "Recording", "SystemInfo", "Tempo", "Privacy", "Settings"]]'

is_recording() {
    [[ -f "$pidfile" ]] && kill -0 "$(cat "$pidfile")" 2>/dev/null
}

mkdir -p "$(dirname "$runtime_config")"
tmp_config="$(mktemp "${runtime_config}.XXXXXX")"

if is_recording; then
    awk -v idle="$idle_modules" -v recording="$recording_modules" '
        $0 == idle {
            print recording
            next
        }
        { print }
    ' "$base_config" >"$tmp_config"
else
    cp "$base_config" "$tmp_config"
fi

mv "$tmp_config" "$runtime_config"

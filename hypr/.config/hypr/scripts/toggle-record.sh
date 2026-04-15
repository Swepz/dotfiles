#!/usr/bin/env bash
#  ______                        __
# /_  __/___  ____ _____ _/ /__       ________  _________  _________/ /
#  / / / __ \/ __ `/ __ `/ / _ \     / ___/ _ \/ ___/ __ \/ ___/ __  /
# / / / /_/ / /_/ / /_/ / /  __/    / /  /  __/ /__/ /_/ / /  / /_/ /
#/_/  \____/\__, /\__, /_/\___/    /_/   \___/\___/\____/_/   \__,_/
#          /____//____/
#
# Toggle region screen recording with wf-recorder + slurp.
# - First invocation: pick a region with slurp, start recording to ~/Videos/rec-<ts>.mkv
# - Second invocation (while recording): SIGINT wf-recorder to flush the file cleanly
# - flock prevents a double-press race
# - Pokes waybar's custom/recording module via SIGRTMIN+8 so the indicator updates instantly

set -u

LOCK=/tmp/toggle-record.lock
PIDFILE=/tmp/wf-recorder.pid
OUTDIR="$HOME/Videos"
WAYBAR_SIGNAL=8

mkdir -p "$OUTDIR"

# Serialize invocations
exec 9>"$LOCK"
flock -n 9 || exit 0

refresh_waybar() {
    pkill -RTMIN+${WAYBAR_SIGNAL} waybar 2>/dev/null || true
}

is_recording() {
    [[ -f "$PIDFILE" ]] && kill -0 "$(cat "$PIDFILE")" 2>/dev/null
}

if is_recording; then
    pid="$(cat "$PIDFILE")"
    kill -INT "$pid" 2>/dev/null || true
    # Wait briefly for wf-recorder to finish writing the container
    for _ in 1 2 3 4 5 6 7 8 9 10; do
        kill -0 "$pid" 2>/dev/null || break
        sleep 0.2
    done
    rm -f "$PIDFILE"
    notify-send -t 2000 -i media-record "Recording stopped" "Saved to $OUTDIR"
    refresh_waybar
    exit 0
fi

# Not recording: prompt for region
REGION=$(slurp -b "#00000080" -c "#ff4444ff" -w 2) || exit 0
[[ -z "$REGION" ]] && exit 0

FILE="$OUTDIR/rec-$(date +%Y-%m-%d_%H-%M-%S).mkv"

# Start recorder in background, capture its PID.
#
# `9>&-` closes the flock file descriptor in the child so wf-recorder does
# NOT inherit the lock. Without this, the lock would stay held for
# wf-recorder's entire lifetime and every subsequent invocation of this script
# would silently exit at `flock -n 9 || exit 0`.
#
# Color handling: we do NOT try to set BT.709 metadata here. wf-recorder's
# source filter tags frames as "unknown", which causes scale=out_range=tv to
# no-op, and `-p colormatrix=bt709` is not forwarded to libavcodec's
# AVCodecContext color fields — verified empirically, the output still reads
# `color_space=unknown`. The washed-out playback the user was seeing was
# NOT a file problem at all: it's a known Hyprland ≥ 0.53 bug in the
# color-management-v1 protocol handling, which mpv triggers by default and
# VLC does not. Fixed via `target-colorspace-hint=no` in ~/.config/mpv/mpv.conf.
# See https://github.com/hyprwm/Hyprland/pull/12781.
wf-recorder -g "$REGION" -f "$FILE" -c libx264 -x yuv420p -y \
    </dev/null >/tmp/wf-recorder.log 2>&1 9>&- &
pid=$!
echo "$pid" > "$PIDFILE"

# Give wf-recorder a moment to either bind the screencopy or fail
sleep 0.3
if ! kill -0 "$pid" 2>/dev/null; then
    rm -f "$PIDFILE"
    notify-send -u critical -t 4000 -i dialog-error "Recording failed to start" "$(tail -n 3 /tmp/wf-recorder.log)"
    refresh_waybar
    exit 1
fi

notify-send -t 2000 -i media-record "Recording started" "Click the ● REC indicator or press the hotkey again to stop"
refresh_waybar

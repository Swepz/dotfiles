#!/usr/bin/env bash
#  ______                        __
# /_  __/___  ____ _____ _/ /__       ________  _________  _________/ /
#  / / / __ \/ __ `/ __ `/ / _ \     / ___/ _ \/ ___/ __ \/ ___/ __  /
# / / / /_/ / /_/ / /_/ / /  __/    / /  /  __/ /__/ /_/ / /  / /_/ /
#/_/  \____/\__, /\__, /_/\___/    /_/   \___/\___/\____/_/   \__,_/
#          /____//____/
#
# Toggle region screen recording with gpu-screen-recorder + slurp.
# - First invocation: pick a region with slurp, start recording to ~/Videos/rec-<ts>.mp4
# - Second invocation (while recording): SIGINT gpu-screen-recorder to flush the file cleanly
# - flock prevents a double-press race
# - Pokes waybar's custom/recording module via SIGRTMIN+8 so the indicator updates instantly

set -u

LOCK=/tmp/toggle-record.lock
PIDFILE=/tmp/gpu-screen-recorder.pid
LOGFILE=/tmp/gpu-screen-recorder.log
STATEFILE=/tmp/gpu-screen-recorder.status
OUTDIR="$HOME/Videos"
WAYBAR_SIGNAL=8

mkdir -p "$OUTDIR"

# Serialize invocations
exec 9>"$LOCK"
flock -n 9 || exit 0

refresh_recording_indicators() {
    printf '%s\n' "$(date +%s)" >>"$STATEFILE" 2>/dev/null || true
    pkill -RTMIN+${WAYBAR_SIGNAL} waybar 2>/dev/null || true
}

is_recording() {
    [[ -f "$PIDFILE" ]] && kill -0 "$(cat "$PIDFILE")" 2>/dev/null
}

if is_recording; then
    pid="$(cat "$PIDFILE")"
    kill -INT "$pid" 2>/dev/null || true
    # Wait briefly for gpu-screen-recorder to finish writing the container
    for _ in 1 2 3 4 5 6 7 8 9 10; do
        kill -0 "$pid" 2>/dev/null || break
        sleep 0.2
    done
    rm -f "$PIDFILE"
    notify-send -t 2000 -i media-record "Recording stopped" "Saved to $OUTDIR"
    refresh_recording_indicators
    exit 0
fi

# Not recording: prompt for region
REGION=$(slurp -b "#00000080" -c "#ff4444ff" -w 2) || exit 0
[[ -z "$REGION" ]] && exit 0

if [[ "$REGION" =~ ^([0-9]+),([0-9]+)[[:space:]]+([0-9]+)x([0-9]+)$ ]]; then
    GSR_REGION="${BASH_REMATCH[3]}x${BASH_REMATCH[4]}+${BASH_REMATCH[1]}+${BASH_REMATCH[2]}"
else
    notify-send -u critical -t 4000 -i dialog-error "Recording failed to start" "Could not parse region: $REGION"
    refresh_recording_indicators
    exit 1
fi

FILE="$OUTDIR/rec-$(date +%Y-%m-%d_%H-%M-%S).mp4"

# Start recorder in background, capture its PID.
#
# `9>&-` closes the flock file descriptor in the child so gpu-screen-recorder does
# NOT inherit the lock. Without this, the lock would stay held for
# gpu-screen-recorder's entire lifetime and every subsequent invocation of this script
# would silently exit at `flock -n 9 || exit 0`.
gpu-screen-recorder -w "$GSR_REGION" -f 60 -k h264 -c mp4 -o "$FILE" \
    </dev/null >"$LOGFILE" 2>&1 9>&- &
pid=$!
echo "$pid" > "$PIDFILE"

# Give gpu-screen-recorder a moment to either bind capture or fail
sleep 0.3
if ! kill -0 "$pid" 2>/dev/null; then
    rm -f "$PIDFILE"
    notify-send -u critical -t 4000 -i dialog-error "Recording failed to start" "$(tail -n 3 "$LOGFILE")"
    refresh_recording_indicators
    exit 1
fi

notify-send -t 2000 -i media-record "Recording started" "Click the ● REC indicator or press the hotkey again to stop"
refresh_recording_indicators

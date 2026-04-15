#!/usr/bin/env bash
#  ____                          _ _
# |  _ \ ___  ___ ___  _ __ __| (_)_ __   __ _
# | |_) / _ \/ __/ _ \| '__/ _` | | '_ \ / _` |
# |  _ <  __/ (_| (_) | | | (_| | | | | | (_| |
# |_| \_\___|\___\___/|_|  \__,_|_|_| |_|\__, |
#                                        |___/
#
# Waybar status script for wf-recorder.
# Returns JSON: a REC indicator when wf-recorder is running, empty otherwise.
# Designed to be driven by SIGRTMIN+8 from toggle-record.sh — no polling needed.

PIDFILE=/tmp/wf-recorder.pid

if [[ -f $PIDFILE ]] && kill -0 "$(cat "$PIDFILE")" 2>/dev/null; then
    printf '{"text":"● REC","class":"recording","tooltip":"Recording in progress — click to stop","alt":"recording"}\n'
else
    printf '{"text":"","class":"idle","alt":"idle"}\n'
fi

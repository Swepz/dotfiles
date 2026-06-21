#!/usr/bin/env bash
set -euo pipefail

# Stream swaync's subscribe-waybar state to ashell's CustomModule listen_cmd.
# swaync emits {"text":"<count>","alt":"<state>",...}; ashell reads text+alt.
# Blank the count when it is exactly 0 so the bell shows icon-only when nothing is pending.
swaync-client -swb 2>/dev/null | sed -u 's/"text": "0"/"text": ""/'

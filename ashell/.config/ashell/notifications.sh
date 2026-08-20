#!/usr/bin/env bash
set -euo pipefail

swaync-client -swb 2>/dev/null | sed -u 's/"text": "0"/"text": ""/'

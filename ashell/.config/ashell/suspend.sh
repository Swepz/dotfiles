#!/usr/bin/env bash
set -euo pipefail

loginctl lock-session
pkill -x ashell 2>/dev/null || true

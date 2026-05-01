#!/usr/bin/env bash
set -euo pipefail

if pids=$(pidof ashell 2>/dev/null); then
    kill -SIGUSR1 $pids
else
    "$HOME/.config/ashell/launch.sh"
fi

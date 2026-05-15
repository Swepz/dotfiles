#!/usr/bin/env bash
set -euo pipefail

walk_mode_service="${CLAMSHELL_WALK_MODE_SERVICE:-clamshell-walk-mode.service}"

if systemctl --user is-active --quiet "$walk_mode_service"; then
	action=(loginctl lock-session)
elif systemd-analyze cat-config systemd/sleep.conf 2>/dev/null | rg -q '^[[:space:]]*SuspendState=freeze([[:space:]]|$)'; then
	action=(systemctl suspend)
else
	action=(loginctl lock-session)
fi

if [[ "${1:-}" == "--dry-run" ]]; then
	printf '%q ' "${action[@]}"
	printf '\n'
	exit 0
fi

exec "${action[@]}"

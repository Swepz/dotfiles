#!/usr/bin/env bash
set -euo pipefail

root_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
config_dir="$root_dir/hypr/.config/hypr"
profiles_dir="$root_dir/hyprdynamicmonitors/.config/hyprdynamicmonitors"
runtime_dir="$(mktemp -d)"
trap 'rm -rf -- "$runtime_dir"' EXIT

cp "$config_dir/hyprland.lua" "$runtime_dir/hyprland.lua"
printf '%s\n' 'hl.monitor({ output = "", mode = "preferred", position = "auto", scale = 1 })' > "$runtime_dir/monitors.lua"
mkdir -p "$runtime_dir/dms"
touch "$runtime_dir/dms/colors.lua" "$runtime_dir/dms/layout.lua"

verify_output="$(cd "$runtime_dir" && Hyprland --verify-config --config "$runtime_dir/hyprland.lua" 2>&1)"
rg -q '^config ok$' <<<"$verify_output"

hyprdynamicmonitors validate --config "$profiles_dir/config.toml"
render_output="$(hyprdynamicmonitors run --config "$profiles_dir/config.toml" --run-once --dry-run --enable-lid-events 2>&1)"
rg -q 'Run succeeded, exiting' <<<"$render_output"

printf 'ok - lua compositor config\n'

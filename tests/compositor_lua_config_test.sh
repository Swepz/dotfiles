#!/usr/bin/env bash
set -euo pipefail

root_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
config_dir="$root_dir/hypr/.config/hypr"
profiles_dir="$root_dir/hyprdynamicmonitors/.config/hyprdynamicmonitors"
runtime_dir="$(mktemp -d)"
trap 'rm -rf -- "$runtime_dir"' EXIT

cp "$config_dir/hyprland.lua" "$runtime_dir/hyprland.lua"
cp "$profiles_dir/hyprconfigs/fallback.lua" "$runtime_dir/monitors.lua"

verify_output="$(cd "$runtime_dir" && Hyprland --verify-config --config "$runtime_dir/hyprland.lua" 2>&1)"
rg -q '^config ok$' <<<"$verify_output"

hyprdynamicmonitors validate --config "$profiles_dir/config.toml"
render_output="$(hyprdynamicmonitors run --config "$profiles_dir/config.toml" --run-once --dry-run --enable-lid-events 2>&1)"
rg -q 'Templated data:' <<<"$render_output"
rg -q 'Run succeeded, exiting' <<<"$render_output"

printf 'ok - lua compositor config\n'

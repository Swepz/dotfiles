#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

fail() {
    printf 'FAIL: %s\n' "$*" >&2
    exit 1
}

assert_file_contains() {
    local file="$1"
    local expected="$2"

    [[ -f "$file" ]] || fail "missing file $file"
    rg -q --fixed-strings -- "$expected" "$file" || {
        printf -- '--- %s ---\n' "$file" >&2
        cat "$file" >&2
        fail "expected '$expected' in $file"
    }
}

assert_file_not_contains() {
    local file="$1"
    local unexpected="$2"

    [[ -f "$file" ]] || fail "missing file $file"
    if rg -q --fixed-strings -- "$unexpected" "$file"; then
        printf -- '--- %s ---\n' "$file" >&2
        cat "$file" >&2
        fail "did not expect '$unexpected' in $file"
    fi
}

make_env() {
    TEST_DIR="$(mktemp -d)"
    export TEST_DIR
    export HOME="$TEST_DIR/home"

    mkdir -p "$HOME"
}

test_walk_mode_ashell_settings_button_is_wired() {
    assert_file_contains "$ROOT_DIR/ashell/.config/ashell/config.toml" '[[settings.CustomButton]]'
    assert_file_contains "$ROOT_DIR/ashell/.config/ashell/config.toml" 'name = "Walk Mode"'
    assert_file_contains "$ROOT_DIR/ashell/.config/ashell/config.toml" 'command = "~/.config/ashell/walk-mode.sh toggle"'
    assert_file_contains "$ROOT_DIR/ashell/.config/ashell/config.toml" 'status_command = "~/.config/ashell/walk-mode.sh status"'
}

test_walk_mode_service_uses_systemd_inhibit() {
    local service_file="$ROOT_DIR/ashell/.config/systemd/user/clamshell-walk-mode.service"

    assert_file_contains "$service_file" "ExecStart=/usr/bin/systemd-inhibit"
    assert_file_contains "$service_file" "--what=sleep:idle:handle-lid-switch"
    assert_file_contains "$service_file" "/usr/bin/sleep infinity"
}

test_logind_handles_clamshell_policy() {
    local services_file="$ROOT_DIR/ansible/roles/services/tasks/main.yml"
    local monitors_file="$ROOT_DIR/hyprdynamicmonitors/.config/hyprdynamicmonitors/config.toml"

    assert_file_contains "$services_file" 'HandleLidSwitch=suspend'
    assert_file_contains "$services_file" 'HandleLidSwitchExternalPower=suspend'
    assert_file_contains "$services_file" 'HandleLidSwitchDocked=ignore'
    assert_file_contains "$services_file" '/etc/systemd/logind.conf.d/10-hyprland-clamshell.conf'
    assert_file_contains "$services_file" '/etc/systemd/logind.conf.d/lid-switch.conf'
    assert_file_contains "$services_file" 'state: reloaded'
    assert_file_not_contains "$monitors_file" 'clamshell-close.sh'
}

test_workspaces_are_monitor_specific() {
    local config_file="$ROOT_DIR/ashell/.config/ashell/config.toml"

    assert_file_contains "$config_file" 'visibility_mode = "MonitorSpecific"'
    assert_file_contains "$config_file" 'enable_workspace_filling = false'
    assert_file_not_contains "$config_file" 'visibility_mode = "All"'
}

test_sleep_locks_without_restarting_ashell() {
    local config_file="$ROOT_DIR/hypr/.config/hypr/hypridle.conf"

    assert_file_contains "$config_file" 'before_sleep_cmd = loginctl lock-session'
    assert_file_not_contains "$config_file" 'suspend.sh'
    assert_file_not_contains "$config_file" 'resume.sh'
}

test_recording_module_is_not_in_base_topbar() {
    assert_file_contains "$ROOT_DIR/ashell/.config/ashell/config.toml" 'right = [["MediaPlayer", "Tray", "SystemInfo", "Tempo", "Privacy", "CustomNotifications", "Settings"]]'
    assert_file_contains "$ROOT_DIR/ashell/.config/ashell/config.toml" 'name = "Recording"'
}

test_recording_runtime_config_excludes_recording_when_idle() {
    make_env
    local runtime_config="$TEST_DIR/ashell-runtime.toml"
    local recording_pidfile="$TEST_DIR/gpu-screen-recorder.pid"

    ASHELL_BASE_CONFIG="$ROOT_DIR/ashell/.config/ashell/config.toml" \
    ASHELL_RUNTIME_CONFIG="$runtime_config" \
    RECORDING_PIDFILE="$recording_pidfile" \
        "$ROOT_DIR/ashell/.config/ashell/render-config.sh"

    assert_file_contains "$runtime_config" 'right = [["MediaPlayer", "Tray", "SystemInfo", "Tempo", "Privacy", "CustomNotifications", "Settings"]]'
    assert_file_not_contains "$runtime_config" 'right = [["MediaPlayer", "Tray", "Recording", "SystemInfo", "Tempo", "Privacy", "CustomNotifications", "Settings"]]'
}

test_recording_runtime_config_includes_recording_when_active() {
    make_env
    local runtime_config="$TEST_DIR/ashell-runtime.toml"
    local recording_pidfile="$TEST_DIR/gpu-screen-recorder.pid"

    sleep 30 &
    local fake_recorder_pid="$!"
    printf '%s\n' "$fake_recorder_pid" > "$recording_pidfile"
    trap 'kill "$fake_recorder_pid" 2>/dev/null || true' RETURN

    ASHELL_BASE_CONFIG="$ROOT_DIR/ashell/.config/ashell/config.toml" \
    ASHELL_RUNTIME_CONFIG="$runtime_config" \
    RECORDING_PIDFILE="$recording_pidfile" \
        "$ROOT_DIR/ashell/.config/ashell/render-config.sh"

    assert_file_contains "$runtime_config" 'right = [["MediaPlayer", "Tray", "Recording", "SystemInfo", "Tempo", "Privacy", "CustomNotifications", "Settings"]]'
    kill "$fake_recorder_pid" 2>/dev/null || true
    trap - RETURN
}

test_recording_toggle_refreshes_ashell_runtime_config() {
    assert_file_contains "$ROOT_DIR/hypr/.config/hypr/scripts/toggle-record.sh" 'ASHELL_CONFIG_RENDER="${ASHELL_CONFIG_RENDER:-$HOME/.config/ashell/render-config.sh}"'
    assert_file_contains "$ROOT_DIR/hypr/.config/hypr/scripts/toggle-record.sh" '"$ASHELL_CONFIG_RENDER" 2>/dev/null || true'
}

test_walk_mode_ashell_settings_button_is_wired
test_walk_mode_service_uses_systemd_inhibit
test_logind_handles_clamshell_policy
test_workspaces_are_monitor_specific
test_sleep_locks_without_restarting_ashell
test_recording_module_is_not_in_base_topbar
test_recording_runtime_config_excludes_recording_when_idle
test_recording_runtime_config_includes_recording_when_active
test_recording_toggle_refreshes_ashell_runtime_config

printf 'ok - ashell sleep hooks\n'

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

write_hyprctl_stub() {
    local bin_dir="$1"

    cat >"$bin_dir/hyprctl" <<'STUB'
#!/usr/bin/env bash
set -euo pipefail

case "$*" in
    "dispatch hl.dsp.dpms({ action = \"enable\" })")
        printf 'display power enable\n' >>"$CALL_LOG"
        ;;
    "monitors -j")
        cat "$MONITORS_JSON"
        ;;
    *)
        printf 'unexpected hyprctl call: %s\n' "$*" >&2
        exit 64
        ;;
esac
STUB
    chmod +x "$bin_dir/hyprctl"
}

write_launch_stub() {
    local path="$1"

    cat >"$path" <<'STUB'
#!/usr/bin/env bash
set -euo pipefail
printf 'launch\n' >>"$CALL_LOG"
STUB
    chmod +x "$path"
}

write_clamshell_stubs() {
    local bin_dir="$1"

    cat >"$bin_dir/systemd-analyze" <<'STUB'
#!/usr/bin/env bash
set -euo pipefail
[[ "$*" == "cat-config systemd/sleep.conf" ]]
printf '[Sleep]\nSuspendState=freeze\n'
STUB
    chmod +x "$bin_dir/systemd-analyze"

    cat >"$bin_dir/systemctl" <<'STUB'
#!/usr/bin/env bash
set -euo pipefail

case "$*" in
    "--user is-active --quiet clamshell-walk-mode.service")
        printf 'systemctl --user is-active --quiet clamshell-walk-mode.service\n' >>"$CALL_LOG"
        [[ "${WALK_MODE_ACTIVE:-0}" == "1" ]]
        ;;
    "suspend")
        printf 'systemctl suspend\n' >>"$CALL_LOG"
        ;;
    *)
        printf 'unexpected systemctl call: %s\n' "$*" >&2
        exit 64
        ;;
esac
STUB
    chmod +x "$bin_dir/systemctl"

    cat >"$bin_dir/loginctl" <<'STUB'
#!/usr/bin/env bash
set -euo pipefail
[[ "$*" == "lock-session" ]]
printf 'loginctl lock-session\n' >>"$CALL_LOG"
STUB
    chmod +x "$bin_dir/loginctl"
}

make_env() {
    TEST_DIR="$(mktemp -d)"
    export TEST_DIR
    export HOME="$TEST_DIR/home"
    export XDG_RUNTIME_DIR="$TEST_DIR/run"
    export HYPRLAND_INSTANCE_SIGNATURE="test-sig"
    export CALL_LOG="$TEST_DIR/calls.log"
    export MONITORS_JSON="$TEST_DIR/monitors.json"
    export PATH="$TEST_DIR/bin:$PATH"
    export ASHELL_LAUNCH="$TEST_DIR/launch-ashell"
    export ASHELL_RESUME_EVENT_TIMEOUT="1s"

    mkdir -p "$HOME" "$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE" "$TEST_DIR/bin"
    : >"$CALL_LOG"

    write_hyprctl_stub "$TEST_DIR/bin"
    write_launch_stub "$ASHELL_LAUNCH"
}

test_resume_launches_when_monitor_is_ready() {
    make_env
    cat >"$MONITORS_JSON" <<'JSON'
[{"name":"eDP-1","disabled":false,"dpmsStatus":true}]
JSON

    "$ROOT_DIR/ashell/.config/ashell/resume.sh"

    assert_file_contains "$CALL_LOG" "display power enable"
    assert_file_contains "$CALL_LOG" "launch"
}

test_resume_waits_for_monitor_event() {
    make_env
    cat >"$MONITORS_JSON" <<'JSON'
[{"name":"eDP-1","disabled":true,"dpmsStatus":false}]
JSON

    cat >"$TEST_DIR/bin/socat" <<'STUB'
#!/usr/bin/env bash
set -euo pipefail
cat >"$MONITORS_JSON" <<'JSON'
[{"name":"eDP-1","disabled":false,"dpmsStatus":true}]
JSON
printf 'monitoraddedv2>>0,eDP-1\n'
STUB
    chmod +x "$TEST_DIR/bin/socat"

    "$ROOT_DIR/ashell/.config/ashell/resume.sh"

    assert_file_contains "$CALL_LOG" "display power enable"
    assert_file_contains "$CALL_LOG" "launch"
}

test_suspend_locks_then_stops_ashell() {
    make_env

    cat >"$TEST_DIR/bin/loginctl" <<'STUB'
#!/usr/bin/env bash
set -euo pipefail
[[ "$*" == "lock-session" ]]
printf 'loginctl lock-session\n' >>"$CALL_LOG"
STUB
    chmod +x "$TEST_DIR/bin/loginctl"

    cat >"$TEST_DIR/bin/pkill" <<'STUB'
#!/usr/bin/env bash
set -euo pipefail
[[ "$*" == "-x ashell" ]]
printf 'pkill -x ashell\n' >>"$CALL_LOG"
STUB
    chmod +x "$TEST_DIR/bin/pkill"

    "$ROOT_DIR/ashell/.config/ashell/suspend.sh"

    local calls
    calls="$(cat "$CALL_LOG")"
    [[ "$calls" == $'loginctl lock-session\npkill -x ashell' ]] || {
        printf '%s\n' "$calls" >&2
        fail "unexpected suspend command order"
    }
}

test_clamshell_walk_mode_locks_without_suspend() {
    make_env
    write_clamshell_stubs "$TEST_DIR/bin"
    export WALK_MODE_ACTIVE=1

    "$ROOT_DIR/hypr/.config/hypr/scripts/clamshell-close.sh"

    local calls
    calls="$(cat "$CALL_LOG")"
    [[ "$calls" == $'systemctl --user is-active --quiet clamshell-walk-mode.service\nloginctl lock-session' ]] || {
        printf '%s\n' "$calls" >&2
        fail "walk mode should lock without suspending"
    }
}

test_clamshell_without_walk_mode_suspends_when_freeze_is_configured() {
    make_env
    write_clamshell_stubs "$TEST_DIR/bin"
    export WALK_MODE_ACTIVE=0

    "$ROOT_DIR/hypr/.config/hypr/scripts/clamshell-close.sh"

    local calls
    calls="$(cat "$CALL_LOG")"
    [[ "$calls" == $'systemctl --user is-active --quiet clamshell-walk-mode.service\nsystemctl suspend' ]] || {
        printf '%s\n' "$calls" >&2
        fail "normal clamshell close should suspend when freeze is configured"
    }
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

test_resume_launches_when_monitor_is_ready
test_resume_waits_for_monitor_event
test_suspend_locks_then_stops_ashell
test_clamshell_walk_mode_locks_without_suspend
test_clamshell_without_walk_mode_suspends_when_freeze_is_configured
test_walk_mode_ashell_settings_button_is_wired
test_walk_mode_service_uses_systemd_inhibit
test_recording_module_is_not_in_base_topbar
test_recording_runtime_config_excludes_recording_when_idle
test_recording_runtime_config_includes_recording_when_active
test_recording_toggle_refreshes_ashell_runtime_config

printf 'ok - ashell sleep hooks\n'

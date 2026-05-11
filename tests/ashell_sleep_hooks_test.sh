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
    rg -q --fixed-strings "$expected" "$file" || {
        printf '--- %s ---\n' "$file" >&2
        cat "$file" >&2
        fail "expected '$expected' in $file"
    }
}

write_hyprctl_stub() {
    local bin_dir="$1"

    cat >"$bin_dir/hyprctl" <<'STUB'
#!/usr/bin/env bash
set -euo pipefail

case "$*" in
    "dispatch dpms on")
        printf 'hyprctl dispatch dpms on\n' >>"$CALL_LOG"
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

    assert_file_contains "$CALL_LOG" "hyprctl dispatch dpms on"
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

    assert_file_contains "$CALL_LOG" "hyprctl dispatch dpms on"
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

test_resume_launches_when_monitor_is_ready
test_resume_waits_for_monitor_event
test_suspend_locks_then_stops_ashell

printf 'ok - ashell sleep hooks\n'

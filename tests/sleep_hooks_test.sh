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

test_walk_mode_service_uses_systemd_inhibit() {
    local service_file="$ROOT_DIR/hypr/.config/systemd/user/clamshell-walk-mode.service"

    assert_file_contains "$service_file" "ExecStart=/usr/bin/systemd-inhibit"
    assert_file_contains "$service_file" "--what=sleep:handle-lid-switch"
    assert_file_contains "$service_file" "/usr/bin/sleep infinity"
}

test_logind_handles_clamshell_policy() {
    local services_file="$ROOT_DIR/ansible/roles/services/tasks/main.yml"
    local monitors_file="$ROOT_DIR/hyprdynamicmonitors/.config/hyprdynamicmonitors/config.toml"

    assert_file_contains "$services_file" 'HandleLidSwitch=suspend'
    assert_file_contains "$services_file" 'HandleLidSwitchExternalPower=suspend'
    assert_file_contains "$services_file" 'HandleLidSwitchDocked=ignore'
    assert_file_contains "$services_file" 'state: reloaded'
    assert_file_not_contains "$monitors_file" 'clamshell-close.sh'
}

test_walk_mode_service_uses_systemd_inhibit
test_logind_handles_clamshell_policy

printf 'ok - sleep hooks\n'

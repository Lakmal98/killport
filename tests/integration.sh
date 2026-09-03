#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPT="$ROOT_DIR/killport.sh"

fail() {
  echo "[integration] FAIL: $*" >&2
  exit 1
}

assert_contains() {
  local haystack="$1"
  local needle="$2"
  local msg="$3"
  [[ "$haystack" == *"$needle"* ]] || fail "$msg (missing '$needle')"
}

setup_mocks() {
  MOCK_DIR="$(mktemp -d)"
  KILL_STATE_FILE="$MOCK_DIR/pids.state"

  cat > "$MOCK_DIR/lsof" <<'LSOF'
#!/usr/bin/env bash
set -euo pipefail
if [ "${LSOF_PERMISSION_DENIED:-0}" = "1" ]; then
  echo "lsof: permission denied" >&2
  exit 1
fi
if [ -n "${LSOF_OUTPUT:-}" ]; then
  printf '%s\n' "$LSOF_OUTPUT" | tr ',' '\n' | sed '/^$/d'
fi
exit 0
LSOF

  cat > "$MOCK_DIR/kill" <<'KILL'
#!/usr/bin/env bash
set -euo pipefail
SIGNAL="TERM"
if [[ "$1" == -* ]]; then
  SIGNAL="${1#-}"
  shift
fi
PID="$1"
STATE_FILE="${KILL_STATE_FILE:?missing KILL_STATE_FILE}"

contains_csv() {
  local list="${1:-}"
  local item="$2"
  IFS=',' read -r -a vals <<< "$list"
  for v in "${vals[@]}"; do
    [ "$v" = "$item" ] && return 0
  done
  return 1
}

is_alive() {
  [ -f "$STATE_FILE" ] || return 1
  grep -qx "$PID" "$STATE_FILE"
}

remove_pid() {
  [ -f "$STATE_FILE" ] || return 0
  grep -vx "$PID" "$STATE_FILE" > "$STATE_FILE.tmp" || true
  mv "$STATE_FILE.tmp" "$STATE_FILE"
}

case "$SIGNAL" in
  0)
    if is_alive; then exit 0; else exit 1; fi
    ;;
  TERM)
    if contains_csv "${TERM_FAIL_PIDS:-}" "$PID"; then
      exit 1
    fi
    if contains_csv "${STUBBORN_PIDS:-}" "$PID"; then
      exit 0
    fi
    remove_pid
    exit 0
    ;;
  KILL)
    if contains_csv "${KILL_FAIL_PIDS:-}" "$PID"; then
      exit 1
    fi
    remove_pid
    exit 0
    ;;
  *)
    exit 1
    ;;
esac
KILL

  cat > "$MOCK_DIR/sudo" <<'SUDO'
#!/usr/bin/env bash
set -euo pipefail
if [ "${SUDO_FAIL:-0}" = "1" ]; then
  exit 1
fi
if [ "${1:-}" = "-n" ]; then
  shift
fi
exec "$@"
SUDO

  chmod +x "$MOCK_DIR/lsof" "$MOCK_DIR/kill" "$MOCK_DIR/sudo"

  export PATH="$MOCK_DIR:$PATH"
  export KILL_STATE_FILE
  export KILL_CMD="$MOCK_DIR/kill"
  export SUDO_CMD="$MOCK_DIR/sudo"
  : > "$KILL_STATE_FILE"
}

teardown_mocks() {
  rm -rf "$MOCK_DIR"
}

run_case() {
  local expected_rc="$1"
  shift

  local output
  set +e
  output="$($SCRIPT "$@" 2>&1)"
  local rc=$?
  set -e

  [ "$rc" -eq "$expected_rc" ] || fail "expected rc=$expected_rc, got rc=$rc, output: $output"
  printf '%s' "$output"
}

setup_mocks

output="$(run_case 65 abc)"
assert_contains "$output" "Invalid port value 'abc'" "invalid input should be reported"

output="$(run_case 0 5432)"
assert_contains "$output" "Port 5432 is already free" "free port should be reported"

printf '%s\n' 101 > "$KILL_STATE_FILE"
export LSOF_OUTPUT="101"
output="$(run_case 0 3000)"
assert_contains "$output" "terminated gracefully" "TERM success should be graceful"

printf '%s\n' 202 > "$KILL_STATE_FILE"
export LSOF_OUTPUT="202"
export STUBBORN_PIDS="202"
output="$(run_case 0 3001)"
assert_contains "$output" "sent SIGKILL" "stubborn process should be force killed"
unset STUBBORN_PIDS

printf '%s\n%s\n' 301 302 > "$KILL_STATE_FILE"
export LSOF_OUTPUT="301,302"
output="$(run_case 0 3002)"
assert_contains "$output" "Sent SIGTERM to PID 301" "first pid should be handled"
assert_contains "$output" "Sent SIGTERM to PID 302" "second pid should be handled"

printf '%s\n' 999 > "$KILL_STATE_FILE"
export LSOF_OUTPUT="999"
export TERM_FAIL_PIDS="999"
export KILL_FAIL_PIDS="999"
export SUDO_FAIL="1"
output="$(run_case 77 3003)"
assert_contains "$output" "Try running with sudo" "permission errors should be actionable"
unset TERM_FAIL_PIDS KILL_FAIL_PIDS SUDO_FAIL

output="$(run_case 64 --file /no/such/file)"
assert_contains "$output" "Port file not found" "missing file should fail clearly"

export LSOF_PERMISSION_DENIED="1"
output="$(run_case 77 3004)"
assert_contains "$output" "Unable to inspect port 3004 due to permissions" "lsof permission failure should be reported"
unset LSOF_PERMISSION_DENIED

teardown_mocks

echo "[integration] PASS"

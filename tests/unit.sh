#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=../killport.sh
source "$ROOT_DIR/killport.sh"

fail() {
  echo "[unit] FAIL: $*" >&2
  exit 1
}

assert_eq() {
  local expected="$1"
  local actual="$2"
  local msg="$3"
  [ "$expected" = "$actual" ] || fail "$msg (expected='$expected', actual='$actual')"
}

output="$(parse_port_token 3000)" || fail "parse_port_token should accept valid port"
assert_eq "3000" "$output" "single port parsing"

output="$(parse_port_token 3000-3002)" || fail "parse_port_token should accept valid range"
assert_eq $'3000\n3001\n3002' "$output" "range parsing"

validate_port_count "$MAX_PORTS" || fail "maximum port count should be accepted"
set +e
validate_port_count $((MAX_PORTS + 1)) >/dev/null 2>/dev/null
rc=$?
set -e
assert_eq "$EXIT_DATAERR" "$rc" "port count above maximum exit code"

set +e
parse_port_token 1-100000 >/dev/null 2>/dev/null
rc=$?
set -e
assert_eq "$EXIT_DATAERR" "$rc" "oversized range exit code"

set +e
parse_port_token 0 >/dev/null 2>/dev/null
rc=$?
set -e
[ "$rc" -ne 0 ] || fail "parse_port_token should reject 0"
assert_eq "$EXIT_DATAERR" "$rc" "port 0 exit code"

set +e
parse_port_token 10-2 >/dev/null 2>/dev/null
rc=$?
set -e
[ "$rc" -ne 0 ] || fail "parse_port_token should reject descending range"
assert_eq "$EXIT_DATAERR" "$rc" "descending range exit code"

tmp_file="$(mktemp)"
cat > "$tmp_file" <<'PORTS'
# comment only
ports:
  - 4000
  - 4002-4003
random text 5000
PORTS

output="$(load_ports_from_file "$tmp_file")" || fail "load_ports_from_file should parse readable file"
rm -f "$tmp_file"
assert_eq $'4000\n4002\n4003\n5000' "$output" "file-based port extraction"

echo "[unit] PASS"

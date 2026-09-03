#!/usr/bin/env bash

set -o pipefail

VERSION="0.4"
KILL_CMD="${KILL_CMD:-/bin/kill}"
SUDO_CMD="${SUDO_CMD:-sudo}"
MAX_PORTS=1024

EXIT_SUCCESS=0
EXIT_USAGE=64
EXIT_DATAERR=65
EXIT_UNAVAILABLE=69
EXIT_NOPERM=77
EXIT_RUNTIME=1

show_usage() {
  cat <<'USAGE'
Usage:
  killport [--yes|-y|--force|--dry-run] [PORT|START-END ...] [-f|--file PORT_FILE]
  killport -h|--help
  killport -v|--version

Description:
  Terminates processes bound to one or more TCP/UDP ports.
  Port arguments can be single ports (3000) or ranges (3000-3010).
  Interactive confirmation is required unless --yes is provided.
  --force skips graceful shutdown and sends SIGKILL immediately.
USAGE
}

error() {
  echo "Error: $*" >&2
}

warn() {
  echo "Warning: $*" >&2
}

show_disclaimer() {
  local yellow=""
  local bold=""
  local reset=""
  local border='+------------------------------------------------------------+'

  if [ -t 2 ] && [ -z "${NO_COLOR:-}" ]; then
    yellow=$'\033[33m'
    bold=$'\033[1m'
    reset=$'\033[0m'
  fi

  printf '%s\n' "${yellow}${border}${reset}" >&2
  printf '%s\n' "${yellow}|${reset} ${bold}WARNING:${reset} killport can terminate running processes.         ${yellow}|${reset}" >&2
  printf '%s\n' "${yellow}|${reset} Review requested ports. Use --dry-run before termination.  ${yellow}|${reset}" >&2
  printf '%s\n' "${yellow}${border}${reset}" >&2
}

require_command() {
  local cmd="$1"
  if ! command -v "$cmd" >/dev/null 2>&1; then
    error "Required command '$cmd' is not available in PATH."
    return "$EXIT_UNAVAILABLE"
  fi
}

is_valid_port_number() {
  local value="$1"
  [[ "$value" =~ ^[0-9]+$ ]] && [ "$value" -ge 1 ] && [ "$value" -le 65535 ]
}

is_valid_pid() {
  [[ "$1" =~ ^[1-9][0-9]*$ ]]
}

validate_port_count() {
  local port_count="$1"
  if [ "$port_count" -gt "$MAX_PORTS" ]; then
    error "Too many ports requested ($port_count). The maximum is $MAX_PORTS per invocation."
    return "$EXIT_DATAERR"
  fi
}

parse_port_token() {
  local token="$1"

  if [[ "$token" =~ ^([0-9]+)-([0-9]+)$ ]]; then
    local start_port="${BASH_REMATCH[1]}"
    local end_port="${BASH_REMATCH[2]}"

    if ! is_valid_port_number "$start_port" || ! is_valid_port_number "$end_port"; then
      error "Invalid port range '$token'. Ports must be between 1 and 65535."
      return "$EXIT_DATAERR"
    fi

    if [ "$start_port" -gt "$end_port" ]; then
      error "Invalid port range '$token'. Range start must be <= end."
      return "$EXIT_DATAERR"
    fi

    validate_port_count $((end_port - start_port + 1)) || return $?

    for ((port=start_port; port<=end_port; port++)); do
      printf '%s\n' "$port"
    done
    return "$EXIT_SUCCESS"
  fi

  if is_valid_port_number "$token"; then
    printf '%s\n' "$token"
    return "$EXIT_SUCCESS"
  fi

  error "Invalid port value '$token'. Use PORT or START-END with values 1..65535."
  return "$EXIT_DATAERR"
}

load_ports_from_file() {
  local file_path="$1"
  local line raw_token
  local found_tokens=0

  if [ ! -f "$file_path" ]; then
    error "Port file not found: $file_path"
    return "$EXIT_USAGE"
  fi

  if [ ! -r "$file_path" ]; then
    error "Port file is not readable: $file_path"
    return "$EXIT_NOPERM"
  fi

  while IFS= read -r line || [ -n "$line" ]; do
    line="${line%%#*}"
    while IFS= read -r raw_token; do
      [ -z "$raw_token" ] && continue
      found_tokens=1
      parse_port_token "$raw_token" || return $?
    done < <(printf '%s\n' "$line" | grep -oE '[0-9]+(-[0-9]+)?' || true)
  done < "$file_path"

  if [ "$found_tokens" -eq 0 ]; then
    warn "No ports found in file: $file_path"
  fi
}

pids_for_port() {
  local port="$1"
  local lsof_out
  local lsof_err

  lsof_out="$(mktemp)"
  lsof_err="$(mktemp)"

  if ! lsof -t -i:"$port" >"$lsof_out" 2>"$lsof_err"; then
    if grep -qi "permission denied" "$lsof_err"; then
      rm -f "$lsof_out" "$lsof_err"
      return "$EXIT_NOPERM"
    fi
  fi

  if [ -s "$lsof_out" ]; then
    while IFS= read -r pid; do
      if is_valid_pid "$pid"; then
        printf '%s\n' "$pid"
      else
        warn "Ignoring invalid PID '$pid' reported for port $port"
      fi
    done < <(sort -u "$lsof_out")
  fi

  rm -f "$lsof_out" "$lsof_err"
  return "$EXIT_SUCCESS"
}

process_port() {
  local port="$1"
  local dry_run="${2:-0}"
  local force="${3:-0}"
  local pid_list
  local pid
  local had_error=0
  local force_attempted=0

  pid_list="$(pids_for_port "$port")"
  case $? in
    "$EXIT_NOPERM")
      error "Unable to inspect port $port due to permissions. Try running with sudo."
      return "$EXIT_NOPERM"
      ;;
  esac

  if [ -z "$pid_list" ]; then
    echo "Port $port is already free"
    return "$EXIT_SUCCESS"
  fi

  if [ "$dry_run" -eq 1 ]; then
    echo "Dry run: would terminate process(es) on port $port: $pid_list"
    return "$EXIT_SUCCESS"
  fi

  echo "Port $port has process(es): $pid_list"

  while IFS= read -r pid; do
    [ -z "$pid" ] && continue

    if [ "$force" -eq 1 ]; then
      force_attempted=1
      if "$KILL_CMD" -KILL -- "$pid" >/dev/null 2>&1; then
        echo "Sent SIGKILL (force) to PID $pid on port $port"
      elif command -v "$SUDO_CMD" >/dev/null 2>&1 && "$SUDO_CMD" -n "$KILL_CMD" -KILL -- "$pid" >/dev/null 2>&1; then
        echo "Sent SIGKILL (force, sudo) to PID $pid on port $port"
      else
        error "Failed to force kill PID $pid on port $port. Try running with sudo."
        had_error=1
      fi
    elif "$KILL_CMD" -TERM -- "$pid" >/dev/null 2>&1; then
      echo "Sent SIGTERM to PID $pid on port $port"
      sleep 0.2
    elif command -v "$SUDO_CMD" >/dev/null 2>&1 && "$SUDO_CMD" -n "$KILL_CMD" -TERM -- "$pid" >/dev/null 2>&1; then
      echo "Sent SIGTERM (sudo) to PID $pid on port $port"
      sleep 0.2
    fi

    if [ "$force_attempted" -eq 0 ] && "$KILL_CMD" -0 -- "$pid" >/dev/null 2>&1; then
      if "$KILL_CMD" -KILL -- "$pid" >/dev/null 2>&1; then
        echo "Process $pid on port $port did not exit gracefully; sent SIGKILL"
      elif command -v "$SUDO_CMD" >/dev/null 2>&1 && "$SUDO_CMD" -n "$KILL_CMD" -KILL -- "$pid" >/dev/null 2>&1; then
        echo "Process $pid on port $port did not exit gracefully; sent SIGKILL with sudo"
      else
        error "Failed to terminate PID $pid on port $port. Try running with sudo."
        had_error=1
      fi
    else
      echo "Process $pid on port $port terminated gracefully"
    fi
  done <<< "$pid_list"

  if [ "$had_error" -eq 1 ]; then
    return "$EXIT_NOPERM"
  fi

  echo "Port $port has been freed"
  return "$EXIT_SUCCESS"
}

main() {
  local ports_file=""
  local port_tokens=()
  local expanded_ports=()
  local parsed_output
  local token
  local port
  local final_rc="$EXIT_SUCCESS"
  local assume_yes=0
  local dry_run=0
  local force=0

  while [ $# -gt 0 ]; do
    case "$1" in
      -y|--yes)
        assume_yes=1
        shift
        ;;
      --dry-run)
        dry_run=1
        shift
        ;;
      --force)
        force=1
        shift
        ;;
      -h|--help)
        show_usage
        return "$EXIT_SUCCESS"
        ;;
      -v|--version)
        echo "killport $VERSION"
        return "$EXIT_SUCCESS"
        ;;
      -f|--file)
        if [ -z "${2:-}" ] || [[ "$2" == -* ]]; then
          error "Missing file path for $1"
          return "$EXIT_USAGE"
        fi
        ports_file="$2"
        shift 2
        ;;
      -* )
        error "Unknown option: $1"
        show_usage
        return "$EXIT_USAGE"
        ;;
      *)
        port_tokens+=("$1")
        shift
        ;;
    esac
  done

  show_disclaimer

  require_command lsof || return $?

  if [ -n "$ports_file" ]; then
    parsed_output="$(load_ports_from_file "$ports_file")" || return $?
    while IFS= read -r port; do
      [ -z "$port" ] && continue
      expanded_ports+=("$port")
    done <<< "$parsed_output"
  fi

  for token in "${port_tokens[@]}"; do
    parsed_output="$(parse_port_token "$token")" || return $?
    while IFS= read -r port; do
      [ -z "$port" ] && continue
      expanded_ports+=("$port")
    done <<< "$parsed_output"
  done

  if [ "${#expanded_ports[@]}" -eq 0 ]; then
    error "No valid ports were provided."
    show_usage
    return "$EXIT_USAGE"
  fi

  mapfile -t expanded_ports < <(printf '%s\n' "${expanded_ports[@]}" | sort -n -u)
  validate_port_count "${#expanded_ports[@]}" || return $?

  if [ "$dry_run" -eq 0 ] && [ "$assume_yes" -eq 0 ]; then
    if [ ! -t 0 ]; then
      error "Interactive confirmation required. Re-run with --yes or --dry-run."
      return "$EXIT_USAGE"
    fi
    printf 'Terminate processes on %s port(s)? [y/N] ' "${#expanded_ports[@]}"
    read -r confirmation
    if [[ ! "$confirmation" =~ ^[Yy]([Ee][Ss])?$ ]]; then
      echo "Aborted."
      return "$EXIT_SUCCESS"
    fi
  fi

  for port in "${expanded_ports[@]}"; do
    process_port "$port" "$dry_run" "$force"
    local rc=$?
    if [ "$rc" -eq "$EXIT_NOPERM" ]; then
      final_rc="$EXIT_NOPERM"
    elif [ "$rc" -ne 0 ] && [ "$final_rc" -eq 0 ]; then
      final_rc="$EXIT_RUNTIME"
    fi
  done

  return "$final_rc"
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  main "$@"
fi

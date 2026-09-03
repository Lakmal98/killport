#!/bin/bash

show_usage() {
  echo "killport [PORT1 PORT2 ...] [-f|--file PORT_FILE] : The PORT(s) must be given as arguments or loaded from a file."
}

load_ports_from_file() {
  local file_path="$1"
  local ports=()

  if [ ! -f "$file_path" ]; then
    echo "Port file not found: $file_path" >&2
    return 1
  fi

  if [ ! -r "$file_path" ]; then
    echo "Port file is not readable: $file_path" >&2
    return 1
  fi

  while IFS= read -r line || [ -n "$line" ]; do
    line="${line%%#*}"
    for extracted_port in $(echo "$line" | grep -oE '[0-9]+'); do
      ports+=("$extracted_port")
    done
  done < "$file_path"

  echo "${ports[@]}"
}

# show an help for argument '-h' or '--help'
if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
  show_usage
usage_message="killport [PORT1 PORT2 ... | START-END ...] : Pass port(s) or range(s) as arguments."

# show an help for argument '-h' or '--help'
if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
  echo "$usage_message"
  exit 0
fi

# show version
if [ "$1" = "-v" ] || [ "$1" = "--version" ]; then
  echo "killport 0.3"
  exit 0
fi

ports_to_kill=()
ports_file=""

while [ $# -gt 0 ]; do
  case "$1" in
    -f|--file)
      if [ -z "$2" ]; then
        echo "Missing file path for $1"
        exit 1
      fi
      ports_file="$2"
      shift 2
      ;;
    -*)
      echo "Unknown option: $1"
      show_usage
      exit 1
      ;;
    *)
      ports_to_kill+=("$1")
      shift
      ;;
  esac
done

if [ -n "$ports_file" ]; then
  loaded_ports=$(load_ports_from_file "$ports_file") || exit 1
  if [ -n "$loaded_ports" ]; then
    for port in $loaded_ports; do
      ports_to_kill+=("$port")
    done
  fi
fi

if [ ${#ports_to_kill[@]} -eq 0 ]; then
  show_usage
if [ $# -eq 0 ]; then
  echo "$usage_message"
  exit 1
fi

killed_ports=()

for port in "${ports_to_kill[@]}"; do
  ! [ "$port" -eq "$port" ] 2>>/dev/null && echo "Invalid argument. PORT number should be a number" && exit 1
process_port() {
  local port="$1"

  if [ $(sudo lsof -t -i:$port | wc -l) -ge 1 ]; then
    sudo kill -9 $(sudo lsof -t -i:$port)
    echo "Port $port has freed up"
    killed_ports+=($port)
  else
    echo "Port $port is already free"
  fi
}

for port_arg in "$@"; do
  if [[ "$port_arg" =~ ^[0-9]+$ ]]; then
    process_port "$port_arg"
  elif [[ "$port_arg" =~ ^([0-9]+)-([0-9]+)$ ]]; then
    start_port="${BASH_REMATCH[1]}"
    end_port="${BASH_REMATCH[2]}"

    if [ "$start_port" -gt "$end_port" ]; then
      echo "Invalid argument. Port range start must be less than or equal to end"
      exit 1
    fi

    for ((port=start_port; port<=end_port; port++)); do
      process_port "$port"
    done
  else
    echo "Invalid argument. PORT should be a number or range (START-END)"
    exit 1
  fi
done

if [ ${#killed_ports[@]} -gt 0 ]; then
  echo "Killed ports: ${killed_ports[@]}"
fi


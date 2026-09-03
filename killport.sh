#!/bin/bash

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

if [ $# -eq 0 ]; then
  echo "$usage_message"
  exit 1
fi

killed_ports=()

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


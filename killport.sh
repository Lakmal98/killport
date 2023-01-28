#!/bin/bash

# show an help for argument '-h' or '--help'
if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
  echo "killport [PORT1 PORT2 ...] : The PORT(s) must given as an argument."
  exit 0
fi

# show version
if [ "$1" = "-v" ] || [ "$1" = "--version" ]; then
  echo "killport 0.3"
  exit 0
fi

if [ $# -eq 0 ]; then
  echo "killport [PORT1 PORT2 ...] : The PORT(s) must given as an argument."
  exit 1
fi

killed_ports=()

for port in "$@"; do
  ! [ "$port" -eq "$port" ] 2>>/dev/null && echo "Invalid argument. PORT number should be a number" && exit 1

  if [ $(sudo lsof -t -i:$port | wc -l) -ge 1 ]; then
    sudo kill -9 $(sudo lsof -t -i:$port)
    echo "Port $port has freed up"
    killed_ports+=($port)
  else
    echo "Port $port is already free"
  fi
done

if [ ${#killed_ports[@]} -gt 0 ]; then
  echo "Killed ports: ${killed_ports[@]}"
fi



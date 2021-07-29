# /bin/bash

[ $# -eq 0 ] && echo "killport [PORT] : The PORT must given as an argument." && exit 1

[ $# -gt 1 ] && echo "Only one argument [PORT] is valid. $# given in." && exit 1

! [ "$1" -eq "$1" ] 2>>log_file && echo "Invalid argument. PORT number should be a number" && exit 1

if [ $(sudo lsof -t -i:$1 | wc -l) -ge 1 ]; then
  sudo kill -9 $(sudo lsof -t -i:$1)
  echo "Port $1 has freed up"
else
  echo "Port $1 is already free"
fi

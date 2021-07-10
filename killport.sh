# /bin/bash

if [ $# -eq 0 ]
  then
    echo "killport [PORT] : The PORT must given as an argument."
    exit
fi

if [ $# -gt 1 ]
  then
    echo "Only one argument [PORT] is valid. $# given in."
    exit
fi

if [ $(sudo lsof -t -i:$1 | wc -l) -ge 1 ]
then
	sudo kill -9 $(sudo lsof -t -i:$1)
	echo "Port $1 is freed up"
else
	echo "Port $1 is free"
fi

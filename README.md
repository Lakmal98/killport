# killport

killport bash application allows to forcefully kill the process associated with any given port numbers and free up the ports.

## Installation

1. > Clone the repository
   > `git clone https://github.com/Lakmal98/killport.git`

2. > Build package using
   > `cd killport; make install`

3. > Give executable permission
   > `sudo chmod +x /usr/bin/killport.sh`

4. > Install
   > `dpkg -i killport.deb`

<!-- Command	Description
killport [PORT1] [PORT2] ... [PORTn]	kill the process associated with given ports
killport -v	show version of the package
killport -h	show help about the package -->

<!-- make a table -->

## Usage

| Command | Description |
| ------- | ----------- |
| killport [PORT1] [PORT2] ... [PORTn] | kill the process associated with given ports |
| killport -v or --version | show version of the package |
| killport -h or --help | show help about the package |


> Ex: To kill port numbers 3000, 8080 and 5000

> `killport 3000 8080 5000`

## Uninstall

> `sudo dpkg -r killport`
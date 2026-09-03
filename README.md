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
| killport -f PORT_FILE or --file PORT_FILE | load ports from a plain text or YAML-formatted file and kill matching processes |
| killport [START-END] | kill processes associated with all ports in the given range |
| killport -v or --version | show version of the package |
| killport -h or --help | show help about the package |


> Ex: To kill port numbers 3000, 8080 and 5000

> `killport 3000 8080 5000`
> Ex: To load ports from a file (plain text or YAML list)
>
> `killport --file ports.yaml`
> Ex: To kill all ports from 3000 to 3010

> `killport 3000-3010`

## Uninstall

> `sudo dpkg -r killport`
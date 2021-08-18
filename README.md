# killport

killport bash application allow to forcefully kill the process associate with any given port number and freed up the port

## Installation

1. > Download the file
   > `wget https://github.com/Lakmal98/killport/blob/main/killport.sh`

2. > Move to a special directory
   > `sudo mv ./killport.sh /usr/bin/`

3. > Give executable permission
   > `sudo chmod +x /usr/bin/killport.sh`

4. > Add an alias to `~/.bashrc` file
   > `alias killport=/usr/bin/killport.sh`

# or

Download and the [debian installation package](https://github.com/Lakmal98/killport/releases)

## Usage

> killport **[PORT]**

###### Ex: To kill port number 3000

> `killport 3000`

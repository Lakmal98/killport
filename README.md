# killport
killport bash application allow to forcefully kill the process associate with any given port number and freed up the port

##Installation

> Download the file
`wget https://github.com/Lakmal98/killport/blob/main/killport.sh`

>Move to a special directory
`sudo mv ./killport.sh /opt/scripts/`

>Give executable permission
`sudo chmod +x /opt/scripts/killport.sh

>Add an alias to `~/.bashrc` file
`alias killport=/opt/scripts/killport.sh

## Usage

> killport **[PORT]**

###### Ex: To kill port number 3000
> `killport 3000`



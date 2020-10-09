# Netcheck
A shellscript to check and log when your internet connection goes down. Netcheck checks for internet connectivity
and if its interupted, writes a log containing the time of disconnect, and length of time disconnected.
Once it reconnects it will log the reconnected internet speed and continue monitoring again.

Netcheck also include an optional web interface for viewing your connection logs remotely from a web browser.
You can use a service such as NGROK to allow you to see the web interface outside of your network.

## Installation

    git clone https://github.com/TristanBrotherton/netcheck.git
    cd netcheck
    chmod +x netcheck.sh
    ./netcheck.sh
    
### CLI Interface
![Netcheck CLI interface](netcheck.png)

### Web Interface
![Netcheck CLI interface](netcheck_remote.png)

## Options
    netcheck.sh -h                                           Display this message
    netcheck.sh -f path/my_log_file.log          Specify log file and path to use
    netcheck.sh -s                                 Disable speedtest on reconnect
    netcheck.sh -c                Check connection ever (n) seconds. Default is 5
    netcheck.sh -u            URL/Host to check, default is http://www.google.com
    netcheck.sh -w                                  Enable the remote webinteface
    netcheck.sh -p                  Specify an optional port for the webinterface
    netcheck.sh -i                           Install netcheck as a system service     

## Run as a service
You can optionally run netcheck as a system service. For systems that use 
systemctl (Linux) you may use its service installation script:

    sudo ./netcheck.sh -i
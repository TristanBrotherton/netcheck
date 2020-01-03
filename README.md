# Netcheck
A shellscript to check and log when your internet connection goes down. Netcheck checks for internet connectivity
and if its interupted, writes a log containing the time of disconnect, and length of time disconnected.
Once it reconnects it will log the reconnected internet speed and continue monitoring again.
# Installation 
  git clone https://github.com/TristanBrotherton/netcheck.git
  cd netcheck
  chmod +x netcheck.sh
  ./netcheck.sh

![Test Image 1](netcheck.png)

# Options
  netcheck.sh -h                                           Display this message
  netcheck.sh -f path/my_log_file.log          Specify log file and path to use
  netcheck.sh -s                                 Disable speedtest on reconnect
  netcheck.sh -c                Check connection ever (n) seconds. Default is 5
  netcheck.sh -u            URL/Host to check, default is http://www.google.com

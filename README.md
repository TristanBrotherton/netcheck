# netcheck
A shellscript to check and log when your internet connection goes down. Netcheck checks for internet connectivity
and if its interupted, writes a log containing the time of disconnect, and length of time disconnected. 
Once it reconnects it will log the reconnected internet speed and continue monitoring again.
# Installation 

::

    git clone https://github.com/TristanBrotherton/netcheck.git
    cd netcheck
    chmod +x netcheck.sh

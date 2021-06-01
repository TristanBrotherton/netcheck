#!/bin/bash

################################################################################
##               Netcheck - Simple internet connection logging                ##
##               https://github.com/TristanBrotherton/netcheck                ##
##                                       -- Tristan Brotherton                ##
################################################################################

VAR_SCRIPTNAME=`basename "$0"`
VAR_SCRIPTLOC="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
VAR_CONNECTED=true
VAR_LOGFILE=log/connection.log
VAR_SPEEDTEST_DISABLED=false
VAR_CHECK_TIME=5
VAR_HOST=http://www.google.com
VAR_ENABLE_WEBINTERFACE=false
VAR_WEB_PORT=9000
VAR_CUSTOM_WEB_PORT=false

COLOR_RED="\033[31m"
COLOR_GREEN="\033[32m"
COLOR_RESET="\033[0m"

STRING_1="LINK RECONNECTED:                               "
STRING_2="LINK DOWN:                                      "
STRING_3="TOTAL DOWNTIME:                                 "
STRING_4="RECONNECTED LINK SPEED:                         "
STRING_5="CONNECTED LINK SPEED:                           "

PRINT_NL() {
  echo
}

PRINT_HR() {
  echo "-----------------------------------------------------------------------------"
}

PRINT_HELP() {
  echo "Here are your options:"
  echo
  echo "$VAR_SCRIPTNAME -h                                           Display this message"
  echo "$VAR_SCRIPTNAME -f path/my_log_file.log          Specify log file and path to use"
  echo "$VAR_SCRIPTNAME -s                                 Disable speedtest on reconnect"
  echo "$VAR_SCRIPTNAME -c                Check connection ever (n) seconds. Default is 5"
  echo "$VAR_SCRIPTNAME -u            URL/Host to check, default is http://www.google.com"
  echo "$VAR_SCRIPTNAME -w                                  Enable the remote webinteface"
  echo "$VAR_SCRIPTNAME -p                  Specify an optional port for the webinterface"  
  echo "$VAR_SCRIPTNAME -i                           Install netcheck as a system service"
  echo "$VAR_SCRIPTNAME -d path/script            Specify script to execute on disconnect"
  echo "$VAR_SCRIPTNAME -r path/script             Specify script to execute on reconnect"
  echo
}

PRINT_MANAGESERVICE() {
  PRINT_HR
  echo "Use the command:"
  echo -e "                                               sudo systemctl$COLOR_GREEN start$COLOR_RESET netcheck"
  echo -e "                                                             $COLOR_RED stop$COLOR_RESET netcheck"
  echo "To manage the service."
  PRINT_HR
}

PRINT_INSTALL() {
  echo
  echo "Installing this library will allow tests of network connection speed."
  echo "https://github.com/sivel/speedtest-cli"
  echo "Installation is a single python file, saved in:"
  echo "$VAR_SCRIPTLOC"
  echo
  echo "Install in this directory now? (y/n)"
}

PRINT_INSTALLING() {
  echo
  echo "Installing https://github.com/sivel/speedtest-cli ..."
}

PRINT_LOGDEST() {
  echo "Logging to:        $VAR_LOGFILE"
}

PRINT_LOGSTART() {
  echo "************ Monitoring started at: $(date "+%a %d %b %Y %H:%M:%S %Z") ************" >> $VAR_LOGFILE
  echo -e "************$COLOR_GREEN Monitoring started at: $(date "+%a %d %b %Y %H:%M:%S %Z") $COLOR_RESET************"
}

PRINT_DISCONNECTED() {
  echo "$STRING_2 $(date "+%a %d %b %Y %H:%M:%S %Z")" >> $VAR_LOGFILE
  echo -e $COLOR_RED"$STRING_2 $(date "+%a %d %b %Y %H:%M:%S %Z")"$COLOR_RESET
}

DISCONNECTED_EVENT_HOOK() {
  if [[ $VAR_ACT_ON_DISCONNECT = true ]]; then :
    COMMAND="$VAR_DISCONNECT_SCRIPT &"
    echo -e $COLOR_RED"$STRING_2 EXEC $COMMAND"$COLOR_RESET
    eval "$COMMAND"
  fi
}

PRINT_RECONNECTED() {
  echo "$STRING_1 $(date "+%a %d %b %Y %H:%M:%S %Z")" >> $VAR_LOGFILE
  echo -e $COLOR_GREEN"$STRING_1 $(date "+%a %d %b %Y %H:%M:%S %Z")"$COLOR_RESET
}

RECONNECTED_EVENT_HOOK() {
  if [[ $VAR_ACT_ON_RECONNECT = true ]]; then :
    COMMAND="$VAR_RECONNECT_SCRIPT $1 &"
    echo -e $COLOR_RED"$STRING_1 EXEC $COMMAND"$COLOR_RESET
    eval "$COMMAND"
  fi
}

PRINT_DURATION() {
  echo "$STRING_3 $(($VAR_DURATION / 60)) minutes and $(($VAR_DURATION % 60)) seconds." | tee -a $VAR_LOGFILE
  echo "$STRING_4" | tee -a $VAR_LOGFILE
}
PRINT_LOGGING_TERMINATED() {
  echo
  echo "************ Monitoring ended at:   $(date "+%a %d %b %Y %H:%M:%S %Z") ************" >> $VAR_LOGFILE
  echo -e "************$COLOR_RED Monitoring ended at:   $(date "+%a %d %b %Y %H:%M:%S %Z") $COLOR_RESET************"
}

GET_LOCAL_IP() {
  ifconfig | sed -En 's/127.0.0.1//;s/.*inet (addr:)?(([0-9]*\.){3}[0-9]*).*/\2/p' | sed -e 's/^/                   http:\/\//' | sed -e "s/.*/&:$1/"
  echo
}

START_WEBSERVER() {
  # Find python version and start corresponding webserver
  VAR_PYTHON_VERSION=$(python -c 'import sys; print(sys.version_info[0])')
  case $VAR_PYTHON_VERSION in
    2)
      (cd $VAR_SCRIPTLOC/log; python -m SimpleHTTPServer $1 &) &> /dev/null  
    ;;
    3)
      (cd $VAR_SCRIPTLOC/log; python -m http.server $1 &) &> /dev/null
    ;;
  esac
}

SETUP_WEBSERVER() {
  if [[ $VAR_ENABLE_WEBINTERFACE = true ]]; then :
    if [[ $VAR_CUSTOM_LOG = true ]]; then :
      echo -e "Web Interface:    $COLOR_RED Not Available $COLOR_RESET"
      echo -e "Custom log destinations are not supported by webinterface"
    else
      echo -e "Web Interface:    $COLOR_GREEN Enabled $COLOR_RESET"
      if [[ $VAR_CUSTOM_WEB_PORT = false ]]; then :
        echo -e "                   http://localhost:$VAR_WEB_PORT"
        GET_LOCAL_IP $VAR_WEB_PORT
        START_WEBSERVER $VAR_WEB_PORT
      else
        echo -e "                   http://localhost:$VAR_CUSTOM_WEB_PORT"
        GET_LOCAL_IP $VAR_CUSTOM_WEB_PORT
        START_WEBSERVER $VAR_CUSTOM_WEB_PORT
      fi
    fi
  fi
}

CHECK_FOR_SPEEDTEST() {
  if [[ $VAR_SPEEDTEST_DISABLED = false ]]; then :
    if [ -f "$VAR_SCRIPTLOC/speedtest-cli.py" ] || [ -f "$VAR_SCRIPTLOC/speedtest-cli" ]; then
        echo -e "SpeedTest-CLI:    $COLOR_GREEN Installed $COLOR_RESET"
        VAR_SPEEDTEST_READY=true
    else
        echo -e "SpeedTest-CLI:    $COLOR_RED Not Installed $COLOR_RESET"
        INSTALL_SPEEDTEST
    fi
    if [ -f "$VAR_SCRIPTLOC/speedtest-cli" ]; then
      mv $VAR_SCRIPTLOC/speedtest-cli $VAR_SCRIPTLOC/speedtest-cli.py
    fi
  else
      echo -e "SpeedTest-CLI:    $COLOR_RED Disabled $COLOR_RESET"
  fi
}

INSTALL_SPEEDTEST() {
  PRINT_INSTALL
  read -r response
  if [[ $response =~ ^([yY][eE][sS]|[yY])$ ]]; then
    PRINT_INSTALLING
    wget -q -O "$VAR_SCRIPTLOC/speedtest-cli.py" https://raw.githubusercontent.com/sivel/speedtest-cli/master/speedtest.py
    chmod +x "$VAR_SCRIPTLOC/speedtest-cli.py"
    PRINT_NL
    CHECK_FOR_SPEEDTEST
  else
    VAR_SPEEDTEST_DISABLED=true
  fi
}

RUN_SPEEDTEST() {
  $VAR_SCRIPTLOC/speedtest-cli.py --simple | sed 's/^/                                                 /' | tee -a $VAR_LOGFILE
}

NET_CHECK() {
  while true; do
    # Check for network connection
    nohup wget -q --tries=5 --timeout=20 -O - $VAR_HOST > /dev/null 2>&1
    if [[ $? -eq 0 ]]; then :
      # We are currently online
      # Did we just reconnect?
      if [[ $VAR_CONNECTED = false ]]; then :
        PRINT_RECONNECTED
        VAR_DURATION=$SECONDS
        PRINT_DURATION
        if [[ $VAR_SPEEDTEST_READY = true ]]; then :
          RUN_SPEEDTEST
        fi
        PRINT_HR | tee -a $VAR_LOGFILE
        SECONDS=0
        VAR_CONNECTED=true
        RECONNECTED_EVENT_HOOK $VAR_DURATION
      fi
    else
      # We are offline
      if [[ $VAR_CONNECTED = false ]]; then :
          # We were already disconnected
        else
          # We just disconnected
          PRINT_DISCONNECTED
          DISCONNECTED_EVENT_HOOK
          SECONDS=0
          VAR_CONNECTED=false
      fi
    fi

    sleep $VAR_CHECK_TIME

  done

}

INSTALL_AS_SERVICE() {
  if ! command -v systemctl &> /dev/null; then
    echo "Systemctl not found."
    echo "Netcheck can only be installed as a service on systems using systemctl."
    echo "You will need to manually setup Netcheck as a service on your system."
    exit
  else 
    FILE=/etc/systemd/system/netcheck.service
    if [ -f "$FILE" ]; then
      echo "Netcheck already installed as a service."
      PRINT_MANAGESERVICE
      exit
    else
      echo "You will need to authenticate using sudo to install."
      echo "Installing netcheck as a service..."
      sudo tee -a /etc/systemd/system/netcheck.service <<EOL >/dev/null
[Unit]
Description=Netcheck Service

[Service]
WorkingDirectory=$VAR_SCRIPTLOC/
ExecStart=$VAR_SCRIPTLOC/$VAR_SCRIPTNAME

[Install]
WantedBy=multi-user.target
EOL
      sudo systemctl enable netcheck.service >/dev/null
      PRINT_MANAGESERVICE
      echo "Would you like to start netcheck as a service now?"
      echo -n "(y/n): "
      read answer
      if [ "$answer" != "${answer#[Yy]}" ] ;then
        sudo systemctl start netcheck
        exit
      else
        exit
      fi
    fi
  fi
}

CLEANUP() {
  if [[ $VAR_INSTALL_AS_SERVICE = false ]]; then :
    PRINT_LOGGING_TERMINATED
  fi
  if [[ $VAR_ENABLE_WEBINTERFACE = true ]]; then :
    echo "Shutting down webinterface..."
    kill 0
  fi
}

trap CLEANUP EXIT
while getopts "f:d:r:c:u:p:whelp-si" opt; do
  case $opt in
    f)
      echo "Logging to custom file: $OPTARG"
      VAR_LOGFILE=$OPTARG
      VAR_CUSTOM_LOG=true
      ;;
    d)
      echo "Executing $OPTARG script on disconnect"
      VAR_DISCONNECT_SCRIPT=$OPTARG
      VAR_ACT_ON_DISCONNECT=true
      ;;
    r)
      echo "Executing $OPTARG script on reconnect"
      VAR_RECONNECT_SCRIPT=$OPTARG
      VAR_ACT_ON_RECONNECT=true
      ;;
    c)
      echo "Checking connection every: $OPTARG seconds"
      VAR_CHECK_TIME=$OPTARG
      ;;
    u)
      echo "Checking host: $OPTARG"
      VAR_HOST=$OPTARG
      ;;
    p)
      echo "Port set to: $OPTARG"
      VAR_CUSTOM_WEB_PORT=$OPTARG
      ;;
    w)
      VAR_ENABLE_WEBINTERFACE=true
      ;;
    s)
      VAR_SPEEDTEST_DISABLED=true
      ;;
    i) 
      VAR_INSTALL_AS_SERVICE=true
      ;;
    h)
      PRINT_HELP
      exit 1
      ;;
    \?)
      echo "Invalid option: -$OPTARG (try -help for clues)"
      exit 1
      ;;
    :)
      echo "Option -$OPTARG requires an argument."
      exit 1
      ;;
  esac
done

if [[ $VAR_INSTALL_AS_SERVICE = true ]]; then :
  INSTALL_AS_SERVICE
fi
PRINT_HR
SETUP_WEBSERVER
CHECK_FOR_SPEEDTEST
PRINT_LOGDEST
PRINT_LOGSTART
if [[ $VAR_SPEEDTEST_READY = true ]]; then :
  echo "$STRING_5" | tee -a $VAR_LOGFILE
  RUN_SPEEDTEST
  PRINT_HR | tee -a $VAR_LOGFILE
fi
NET_CHECK

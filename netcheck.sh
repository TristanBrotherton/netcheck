#!/bin/bash

################################################################################
##               Netcheck - Simple internet connection logging                ##
##               https://github.com/TristanBrotherton/netcheck                ##
##                                       -- Tristan Brotherton                ##
################################################################################

VAR_SCRIPTNAME=`basename "$0"`
VAR_CONNECTED=true
VAR_LOGFILE=connection.log
VAR_SPEEDTEST_DISABLED=false
VAR_CHECK_TIME=5
VAR_HOST=http://www.google.com

COLOR_RED="\033[31m"
COLOR_GREEN="\033[32m"
COLOR_RESET="\033[0m"

STRING_1="LINK RECONNECTED:                               "
STRING_2="LINK DOWN:                                      "
STRING_3="TOTAL DOWNTIME:                                 "
STRING_4="RECONNECTED LINK SPEED:                         "

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
  echo
}

PRINT_INSTALL() {
  echo
  echo
  echo "Installing this library will allow tests of network connection speed."
  echo "https://github.com/sivel/speedtest-cli"
  echo "Installation is a single python file, saved in this directory."
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
  echo "************ Monitoring started at: $(date) ************" >> $VAR_LOGFILE
  echo -e "************$COLOR_GREEN Monitoring started at: $(date) $COLOR_RESET************"
}

PRINT_DISCONNECTED() {
  echo "$STRING_2 $(date)" >> $VAR_LOGFILE
  echo -e $COLOR_RED"$STRING_2 $(date)"$COLOR_RESET
}

PRINT_RECONNECTED() {
  echo "$STRING_1 $(date)" >> $VAR_LOGFILE
  echo -e $COLOR_GREEN"$STRING_1 $(date)"$COLOR_RESET
}

PRINT_DURATION() {
  echo "$STRING_3 $(($VAR_DURATION / 60)) minutes and $(($VAR_DURATION % 60)) seconds." | tee -a $VAR_LOGFILE
  echo "$STRING_4" | tee -a $VAR_LOGFILE
}
PRINT_LOGGING_TERMINATED() {
  echo
  echo "************ Monitoring ended at:   $(date) ************" >> $VAR_LOGFILE
  echo -e "************$COLOR_RED Monitoring ended at:   $(date) $COLOR_RESET************"
}

CHECK_FOR_SPEEDTEST() {
  if [[ $VAR_SPEEDTEST_DISABLED = false ]]; then :
    if [ -f "speedtest-cli" ]; then
        echo -e "SpeedTest-CLI:    $COLOR_GREEN Installed $COLOR_RESET"
        VAR_SPEEDTEST_READY=true
    else
        echo -e "SpeedTest-CLI:    $COLOR_RED Not Installed $COLOR_RESET"
        INSTALL_SPEEDTEST
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
    wget -q -O speedtest-cli https://raw.githubusercontent.com/sivel/speedtest-cli/master/speedtest.py
    chmod +x speedtest-cli
    PRINT_NL
    CHECK_FOR_SPEEDTEST
  else
    VAR_SPEEDTEST_DISABLED=true
  fi
}

RUN_SPEEDTEST() {
  ./speedtest-cli --simple | sed 's/^/                                                 /' | tee -a $VAR_LOGFILE
}

NET_CHECK() {
  while true; do
    # Check for network connection
    wget -q --tries=5 --timeout=20 -O - $VAR_HOST > /dev/null
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
      fi

    else
      # We are offline
      if [[ $VAR_CONNECTED = false ]]; then :
          # We were already disconnected
        else
          # We just disconnected
          PRINT_DISCONNECTED
          SECONDS=0
          VAR_CONNECTED=false
      fi
    fi

    sleep $VAR_CHECK_TIME

  done

}

CLEANUP() {
  PRINT_LOGGING_TERMINATED
}

trap CLEANUP EXIT
while getopts "fcu:help-s" opt; do
  case $opt in
    f)
      echo "Logging to custom file: $OPTARG"
      VAR_LOGFILE=$OPTARG
      ;;
    c)
      echo "Checking connection every: $OPTARG seconds"
      VAR_CHECK_TIME=$OPTARG
      ;;
    u)
      echo "Checking host: $OPTARG"
      VAR_HOST=$OPTARG
      ;;
    s)
      VAR_SPEEDTEST_DISABLED=true
      ;;
    h)
      PRINT_HELP
      exit 1
      ;;
    \?)
      echo "Invalid option: -$OPTARG"
      exit 1
      ;;
    :)
      echo "Option -$OPTARG requires an argument."
      exit 1
      ;;
  esac
done

PRINT_HR
CHECK_FOR_SPEEDTEST
PRINT_LOGDEST
PRINT_LOGSTART
NET_CHECK

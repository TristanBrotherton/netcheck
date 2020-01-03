#!/bin/bash
SCRIPTNAME=`basename "$0"`
CONNECTED=true
LOGFILE=connection.log
SPTST_DISABLED=false

#COLORS
CL_RED="\033[31m"
CL_GREEN="\033[32m"
CL_RESET="\033[0m"

S1="LINK RECONNECTED:                               "
S2="LINK DOWN:                                      "
S3="TOTAL DOWNTIME:                                 "
S4="RECONNECTED LINK SPEED:                         "

PRINT_NL() {
  echo
}

PRINT_HR() {
  echo "-----------------------------------------------------------------------------"
}

PRINT_HELP() {
  echo "Here are your options:"
  echo
  echo "$SCRIPTNAME -h                                           Display this message"
  echo "$SCRIPTNAME -f path/my_log_file.log          Specify log file and path to use"
  echo "$SCRIPTNAME -s                                 Disable speedtest on reconnect"
  echo
}

PRINT_INSTALL() {
  echo
  echo
  echo "Installing this library will allow tests of network connection speed."
  echo "https://github.com/sivel/speedtest-cli"
  echo
  echo "Install in this directory now? (y/n)"
}

PRINT_INSTALLING() {
  echo
  echo "Installing https://github.com/sivel/speedtest-cli ..."
}

PRINT_LOGDEST() {
  echo "Logging to:        $LOGFILE"
}

PRINT_LOGSTART() {
  echo "************ Monitoring started at: $(date) ************" >> $LOGFILE
  echo -e "************$CL_GREEN Monitoring started at: $(date) $CL_RESET************"
}

LOAD_OPTIONS() {
  while getopts ":f:s:help-" opt; do
    case $opt in
      f)
        echo "Logging to custom file: $OPTARG"
        LOGFILE=$OPTARG
        ;;
      s)
        SPTST_DISABLED=true
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
  PR_HR
}

CHECK_FOR_SPEEDTEST() {
  if [[ $SPTST_DISABLED = false ]]; then :
    if [ -f "speedtest-cli" ]; then
        echo -e "SpeedTest-CLI:    $CL_GREEN Installed $CL_RESET"
        SPTST_READY=true
    else
        echo -e "SpeedTest-CLI:    $CL_RED Not Installed $CL_RESET"
        INSTALL_SPEEDTEST
    fi
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
    SPTST_DISABLED=true
  fi
}

NET_CHECK() {
  while true; do
    # Set default connection state
    wget -q --tries=5 --timeout=20 -O - http://www.google.com > /dev/null
    if [[ $? -eq 0 ]]; then :
      # Online
      if [[ $CONNECTED = false ]]; then :
        # We just reconnected
        echo -e $CL_GREEN"$S1 $(date)"$CL_RESET
        echo "$S1 $(date)" | tee -a $LOGFILE
        duration=$SECONDS
        echo "$S3 $(($duration / 60)) minutes and $(($duration % 60)) seconds." | tee -a $LOGFILE
        echo "$S4" | tee -a $LOGFILE
        if [[ $SPTST_READY = true ]]; then :
          ./speedtest-cli --simple | sed 's/^/                                                 /' | tee -a $LOGFILE
        fi
        PRINT_HR | tee -a $LOGFILE
        SECONDS=0
        CONNECTED=true

      fi
    else # We are offline
      if [[ $CONNECTED = false ]]; then :
          # We were already disconnected
        else
          # We just disconnected
          echo -e $CL_RED"$S2 $(date)"$CL_RESET
          echo "$S2 $(date)" | tee -a $LOGFILE
          SECONDS=0
          CONNECTED=false
      fi
    fi

    sleep 5

  done
  echo "*********** Monitoring MB ended at  " $(date) "***********"
}

LOAD_OPTIONS
CHECK_FOR_SPEEDTEST
PRINT_LOGDEST
PRINT_LOGSTART
NET_CHECK

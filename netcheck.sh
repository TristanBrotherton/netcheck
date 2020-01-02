#!/bin/bash
SCRIPTNAME=`basename "$0"`
CONNECTED=true
LOGFILE=connection.log
SPTST_DISABLED=false
S1="LINK RECONNECTED:                               "
S2="LINK DOWN:                                      "
S3="TOTAL DOWNTIME:                                 "
S4="RECONNECTED LINK SPEED:                         "
S5="-----------------------------------------------------------------------------"

#COLORS
CL_RED="\033[31m"
CL_GREEN="\033[32m"
CL_RESET="\033[0m"


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
      echo "Here are your options:"
      echo
      echo "$SCRIPTNAME -h                                           Display this message"
      echo "$SCRIPTNAME -f path/my_log_file.log          Specify log file and path to use"
      echo "$SCRIPTNAME -s                                 Disable speedtest on reconnect"
      echo
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

echo $S5

CHECK_SPTST() {
  if [[ $SPTST_DISABLED = false ]]; then :
    if [ -f "speedtest-cli" ]; then
        echo -e "SpeedTest-CLI:    $CL_GREEN Installed $CL_RESET"
        SPTST_READY=true
    else
        echo -e "SpeedTest-CLI:    $CL_RED Not Installed $CL_RESET"
        INSTALL_SPTST
    fi
  fi
}
INSTALL_SPTST() {
  echo
  echo
  echo "Installing this library will allow tests of network connection speed."
  echo "https://github.com/sivel/speedtest-cli"
  echo
  echo "Install in this directory now? (y/n)"
  read -r response
  if [[ $response =~ ^([yY][eE][sS]|[yY])$ ]]; then
    echo
    echo "Installing https://github.com/sivel/speedtest-cli ..."
    wget -q -O speedtest-cli https://raw.githubusercontent.com/sivel/speedtest-cli/master/speedtest.py
    chmod +x speedtest-cli
    echo
    CHECK_SPTST
  else
    SPTST_DISABLED=true
  fi
}

CHECK_SPTST
echo "Logging to:        $LOGFILE"
echo -e "************$CL_GREEN Monitoring started at: $(date) $CL_RESET************" | tee -a $LOGFILE

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
      echo "$S5" | tee -a $LOGFILE
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

#!/usr/bin/env bash

set -o nounset
log=/usr/local/src/netcheck/log/connection.log

# Parse options
space=" "
style=square
while [[ $# -gt 0 ]]; do
  case "${1}" in
    -s|--style)
      style="${2}"
      shift
      ;;
    -n|--no-space) space="" ;;
    -f)
      log="${2}"
      shift
      ;;
    *)
      echo "Unexpected option ${1}" >&2
      exit 1
      ;;
  esac
  shift
done

# Style argument
case "${style}" in
square)
  char_full="■"
  char_void="${char_full}"
  ;;
block)
  char_full="█"
  char_void="${char_full}"
  ;;
plus)
  char_full="✚"
  char_void="•"
  ;;
*)
  echo "error: style '${style}' not recognized (square block plus)" >&2;
  exit 1;;
esac

# Process link down per day
declare -A commits_per_day
commits_max=0

year=`date +"%Y"`
# since=`date -d "01 Jan $year"`
since=$(date -d "$(date -d '1 year ago + 1 day' +"%F -%u day")" +"%s")

while read -r commits_n commits_date; do
  (( commits_n > commits_max )) && commits_max=$commits_n
  date_diff=$(( ($(date --date="${commits_date} 13:00 UTC" "+%s") - since) / (60*60*24) ))
  commits_per_day["${date_diff}"]=$commits_n
done <<< $(IFS=$'\n' ; for d in `grep $year $log | grep "LINK DOWN" | sed 's/LINK DOWN://' | sed 's/^[ \t]*//'` ; do date -d $d +"%Y-%m-%d" ; done | uniq -c)

# Print name of months
current_month=$(date "+%b")
limit_columns=$(( 2 - ${#space} ))
weeks_in_month=$(( limit_columns + 1 ))
printf "\e[m    "
for week_n in $(seq 0 52); do
  month_week=$(date -d "1 year ago + ${week_n} weeks" "+%b")
  if [[ "${current_month}" != "${month_week}" ]]; then
    current_month=$month_week
    weeks_in_month=0
    printf "%-3s%s" "${current_month:0:3}" "$space"
  elif [[ $weeks_in_month -gt $limit_columns ]]; then
    printf " %s" "$space"
  fi
  weeks_in_month=$(( weeks_in_month + 1 ))
done
printf "\n"

# Print activity
last_day=$(( ($(date "+%s") - since) / (60*60*24) ))
name_of_days=("" "Mon" "" "Wed" "" "Fri" "" "")
for day_n in $(seq 0 6); do
  printf '\e[m%-4s' "${name_of_days[day_n]}"
  for week_n in $(seq 0 52); do
    key=$(( week_n * 7 + day_n ))
    if [[ $commits_max != 0 && -v commits_per_day["${key}"] ]]; then
      value=$(( ${commits_per_day["${key}"]}00 / commits_max))
      if (( value <= 25 )); then
        # Low activity
        printf "\x1b[38;5;22m%s%s" "$char_full" "$space"
      elif (( value <= 50 )); then
        # Mid-low activity
        printf "\x1b[38;5;28m%s%s" "$char_full" "$space"
      elif (( value <= 75 )); then
        # Mid-high activity
        printf "\x1b[38;5;34m%s%s" "$char_full" "$space"
      else
        # High activity
        printf "\x1b[38;5;40m%s%s" "$char_full" "$space"
      fi
    elif [ $key -lt $last_day ]; then
      # No activity
      printf "\x1b[38;5;250m%s%s" "$char_void" "$space"
    fi
  done
  printf "\n"
done
printf "\n"

# Print legend
printf "\e[m Less "
printf "\x1b[38;5;250m%s " "$char_void"
printf "\x1b[38;5;22m%s " "$char_full"
printf "\x1b[38;5;28m%s " "$char_full"
printf "\x1b[38;5;34m%s " "$char_full"
printf "\x1b[38;5;40m%s " "$char_full"
printf "\e[mMore"
printf "\n"

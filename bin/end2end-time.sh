#!/bin/bash

WORK_DIR=$(dirname $0)
source ${WORK_DIR}/time-common

usage()
{
  echo "Usage: test-playground.sh [options]"
  echo "    -h     Display help"
  echo "    -s     EclWatch ip or FQDN"
  echo "    -t     targets. Such as 'hthor roxie thor'"
  exit
}

SERVER=
OUT_DIR=log
TARGETS="hthor roxie-workunit thor"
PORT=8010
while getopts “hs:t:” opt
do
  case $opt in
    o) OUT_DIR=$OPTARG ;;
    s) SERVER=$OPTARG ;;
    t) TARGETS=$OPTARG ;;
    h) usage   ;;
  esac
done
shift $(( $OPTIND-1 ))

[ -z "$SERVER" ] && usage

ECL_DIR=${WORK_DIR}/ecl

mkdir -p $OUT_DIR

total_count=0
total_succeeded=0
total_failed=0
result="OK"
echo "ECL End-to-End Time Tests"
echo "---------------------------------------------------------"
for target in $TARGETS
do
  count=0
  succeeded=0
  failed=0
  log_dir=${OUT_DIR}/${target}
  mkdir -p $log_dir
  echo
  echo "$target"
  echo "============"
  printf "%5s %-36s %10s %15s %15s %12s %12s\n" "INDEX" "NAME" "RESULT" "USER-END" "SERVER-END" "WU-EXEC" "COMPILE"
  for file in $(ls ${ECL_DIR})
  do
    ext=$(echo $file | cut -d'.' -f2)
    [ "$ext" != "ecl" ] && continue
    test_name="$(echo $file | cut -d'.' -f1)"
    count=$(expr $count + 1)
    total_count=$(expr $total_count + 1)
    printf "%5s %-36s" "$count" "$test_name"
    out_file=/tmp/test_playground_time_$$.out
    { time ecl run $target -s $SERVER ${ECL_DIR}/${file} -v  > ${log_dir}/${test_name}.log 2>&1 ; } 2> /tmp/test_playground_time_$$.out
    if [ $? -eq 0 ]
    then
       succeeded=$(expr $succeeded \+ 1)
       total_succeeded=$(expr $total_succeeded \+ 1)
       result=OK
    else
       failed=$(expr $failed \+ 1)
       total_failed=$(expr $total_failed \+ 1)
       result=Failed
    fi
    wuid=$(cat ${log_dir}/${test_name}.log | grep wuid: | cut -d':' -f2 | sed -r 's/\s+//g')
    eclplus server=${SERVER}:${PORT} cluster=${target} wuid=${wuid} dump  > ${OUT_DIR}/wu_dump.out
    get_wu_timers ${OUT_DIR}/wu_dump.out

    user_end_time=$(cat $out_file | grep "^real" | awk '{print $2}')
    user_end_time_min=$(echo $user_end_time | cut -d'm' -f1)
    user_end_time_sec=$(echo $user_end_time | cut -d'm' -f2 | cut -d's' -f1)
    user_end_time="$( echo "scale=3; (($user_end_time_min * 60) + $user_end_time_sec)" | bc )s"

    rm -rf $out_file

    printf " %10s %15s %15s %12s %12s\n" "[ $result ]" "[ $user_end_time ]" "[ $wu_time ]" "[ $wu_execute_time ]" "[ $compile_time ]"
  done
  echo "============"
  echo "Summary ($target):"
  printf "%-15s: %3s\n" "Total tests" "$count"
  printf "%-15s: %3s\n" "Succeeded" "$succeeded"
  printf "%-15s: %3s\n\n" "Failed" "$failed"

done
echo "---------------------------------------------------------"
echo "Summary:"
printf "%-15s: %3s\n" "Total tests" "$total_count"
printf "%-15s: %3s\n" "Succeeded" "$total_succeeded"
printf "%-15s: %3s\n\n" "Failed" "$total_failed"

#!/bin/bash

#
# call dbmotion tool to perform migration task, e.g. meta+data+sync+check
#
# -dbtype=mysql
#

. "$(cd $(dirname "$0");pwd)"/run-util.sh

taskId="$(get_opt_val "uuid-key" "$@")"
peekModel="$(get_opt_val "peek-model" "$@")"

if [[ "$peekModel" == "metadatasync" ]]; then
  echo "migrating meta, data, sync"
  # migrate meta
  dbmotion --move-model=onlymeta "$@"

  # migrate data
  dbmotion --move-model=onlydata "$@"

  # check data after 5 seconds in background
  bg_check_data "$@"

  # migrate changed data
  dbmotion --move-model=onlychanged "$@"

elif [[ "$peekModel" == "metadata" ]]; then
  echo "migrating meta, data"
  # migrate meta
  dbmotion --move-model=onlymeta "$@"

  # migrate data
  dbmotion --move-model=onlydata "$@"

  # check data
  dbmotion --data-check=y "$@"

elif [[ "$peekModel" == "meta" ]]; then
  echo "migrating meta"
  # migrate meta
  dbmotion --move-model=onlymeta "$@"

  # check data
  dbmotion --data-check=y "$@"

elif [[ "$peekModel" == "datasync" ]]; then
  echo "migrating data, sync"
  # migrate data
  dbmotion --move-model=onlydata "$@"

  # check data after 5 seconds in background
  bg_check_data

  # migrate changed data
  dbmotion --move-model=onlychanged "$@"

elif [[ "$peekModel" == "data" ]]; then
  echo "migrating data"
  # migrate data
  dbmotion --move-model=onlydata "$@"

  # check data
  dbmotion --data-check=y "$@"

elif [[ "$peekModel" == "sync" ]]; then
  echo "migrating sync"
  # migrate changed data
  dbmotion --move-model=onlychanged "$@"

else
  echo "invalid -peek-model=$peekModel"
  exit 1
fi
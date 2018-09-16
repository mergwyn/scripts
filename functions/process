#!/bin/bash


checkAlreadyRunning()
{
  process=$1
  # check if there is another instance running
  ps -d | grep -v grep | grep -v $$ | grep "${process}" > /dev/null
  result=$?
  if [[ $result -eq 0 ] ; then
    log_critical "$0 is already running, exiting"
    exit 1
  fi
}

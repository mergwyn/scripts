#!/bin/bash

declare -i sleep=60
declare -i totalSleep=36000
declare -i duration=0

waitForProcess()
{       
  log_info "waiting for process to complete $@"
  until $(ps -d | grep -v grep | grep -v $$ | grep "${@}" > /dev/null)
  do  
    log_debug "waiting for process to complete"
    sleep $sleep
    duration+=$sleep
  done
  log_info "complete waiting for process $@ after $duration seconds"
}

waitForCommand()
{       
  log_info "waiting for command $@"
  until $($@)
  do  
    log_debug "waiting for command to complete"
    sleep $sleep
    duration+=$sleep
  done
  log_info "complete waiting for command $@ after $duration seconds"
}


#!/usr/bin/env bash
# functions to support logging
_xtracewason=

LOGDEST=${LOGDEST:-"auto"}
DEBUGLOG=${DEBUGLOG:-""}
declare -i OUTPUTCOUNT=0
export OUTPUTCOUNT

if [[ ! ${DEBUGLOG} ]]; then
  function _GetxtraceSetting ()   { if [[ -o xtrace ]] ; then _xtracewason="xtracewason"; set +x ; fi } 2>/dev/null
  function _ResetxtraceSetting () { if [[ -n "${_xtracewason}" ]] ; then set -x; fi } 
else
  function _GetxtraceSetting ()   { :; }
  function _ResetxtraceSetting () { :; } 
fi
#_GetxtraceSetting 

declare -i logLevel=0
declare -i messageLevel=0

export LOGLEVEL=${LOGLEVEL:-NOTICE}

enumLogLevel () {
  case "$1" in
  SILENT)	echo 0;;
  CRITICAL)	echo 1;;
  ERROR)	echo 2;;
  WARN)		echo 3;;
  NOTICE)	echo 4;;
  INFO)		echo 5;;
  DEBUG)	echo 6;;
  *)		log_err "Invalid log level $1"
		exit 1;;
  esac
}

log_critical()  { _GetxtraceSetting ; elog CRITICAL "$@"; _ResetxtraceSetting; }
log_error () 	{ _GetxtraceSetting ; elog ERROR "$@";    _ResetxtraceSetting; }
log_warn () 	{ _GetxtraceSetting ; elog WARN "$@";     _ResetxtraceSetting; }
log_notice () 	{ _GetxtraceSetting ; elog NOTICE "$@";   _ResetxtraceSetting; }
log_info () 	{ _GetxtraceSetting ; elog INFO "$@";     _ResetxtraceSetting; }
log_debug () 	{ _GetxtraceSetting ; elog DEBUG "$@";    _ResetxtraceSetting; }

function elog() {
  logLevel=$(enumLogLevel "$LOGLEVEL")
  messageLevel=$(enumLogLevel "$1")
  if [[ $logLevel -ge $messageLevel ]]; then
    OUTPUTCOUNT+=1
    shift
    if [[ $messageLevel -le 4 ]] ; then
      log_err "$@"
    else
      log "$@"
    fi
  fi
}


# set up looging destination
case ${LOGDEST} in
syslog)
  log()        { logger -t    "$(basename "$0")[$$]" -- "$@"; }
  log_err()    { logger -s -t "$(basename "$0")[$$]" -p user.err -- "$@"; }
  log_output() { logger -t    "$(basename "$0")[$$]" -p user.err ; }
  ;;
stdout)
  log()        { echo "$@" ; }
  log_err()    { >&2 echo "$@" ; }
  log_output() { >&2 cat - ; }
  ;;
*)
  # default is to detect whether we are running from a terminal
  log()        { if [[ -t 1 ]] ; then     echo "$@" ; else logger -t    "$(basename "$0")[$$]" -- "$@"; fi }
  log_err()    { if [[ -t 2 ]] ; then >&2 echo "$@" ; else logger -s -t "$(basename "$0")[$$]" -p user.err -- "$@"; fi }
  log_output() { if [[ -t 2 ]] ; then >&2 cat - ;     else logger -t    "$(basename "$0")[$$]" -p user.err ; fi }
  ;; 
esac

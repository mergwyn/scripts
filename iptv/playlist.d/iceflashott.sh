#!/usr/bin/env bash

set -o nounset
#set -o xtrace
set -o errexit
set -o pipefail

LOGLEVEL=${LOGLEVEL:-"INFO"}

# shellcheck disable=1090
source "$(dirname "${0}")"/../../functions/log.sh

XMLTV=/srv/media/xmltv
curl=/opt/puppetlabs/puppet/bin/curl

TMPFILE=$(mktemp --directory --suffix iceflashott)
_input_playlist=${TMPFILE}/iceflashott.m3u
_output_playlist=${TMPFILE}/new.m3u
function finish { rm -rf "${TMPFILE}"; }
trap finish EXIT

DATA="$(dirname "${0}")"/../iptv_urls
if [[ -f "${DATA}" ]] ; then
  # shellcheck disable=1090
  source "${DATA}"
else
  echo "URL file ${DATA} not found" >&2
  exit 1
fi
URL="${ICE_M3U}"

addchannels()
{
  local service=$1
  local url=$2
  local output=${XMLTV}/${service}.m3u

  log_info "Adding $service channels from $url"
  log_debug "output=$output"


  echo "#EXTM3U" > "${_output_playlist}"
  ${curl} --connect-timeout 10 --no-progress-meter --silent --show-error "${URL}" > "${_input_playlist}"
  cat "${_input_playlist}" \
    | grep -vE 'PPV|tvg-id=""' \
    | grep --no-group-separator -A1 'UK|' \
    >> "${_output_playlist}" 
  cp "${_output_playlist}" "${output}"
}


CHANNELS=${XMLTV}/iceflashott.channels
addchannels iceflashott "${URL}"

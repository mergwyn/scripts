#!/usr/bin/env bash

set -o nounset
set -o errexit
set -o pipefail

LOGLEVEL=${LOGLEVEL:-"INFO"}

# shellcheck disable=1090
source "$(dirname "${0}")"/../../functions/log.sh

XMLTV=/srv/media/xmltv
curl=/opt/puppetlabs/puppet/bin/curl

TMPFILE=$(mktemp --suffix .m3u)
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
URL="${NORD_M3U}"

channel=
sedscript_filter=
sedscript_rename=

# channels to filtered
sedscript_filter+='/#EXTM3U/d;'
sedscript_filter+='/group-title="UK KIDS/,+1 d;'
sedscript_filter+='/group-title="UK VIP KIDS/,+1 d;'
sedscript_filter+='/group-title="UK VIP DOCUMENTARIES/,+1 d;'
sedscript_filter+='/group-title="UK EPL 3PM/,+1 d;'
sedscript_filter+='/group-title="UK MUSIC-NEWS/,+1 d;'
sedscript_filter+='/group-title="UK VIP MUSIC-NEWS/,+1 d;'
sedscript_filter+='/tvg-name="-----/,+1 d;'

while read -r pattern ; do
  sedscript_filter+="/$pattern/,+1 p;"
done <<EOF
group-title=\"UK
EOF

# channels to be mapped
while IFS='~' read -r pattern1 pattern2 ; do
  sedscript_rename+="s~$pattern1~$pattern2~g;"
done <<EOF
EOF

getChannelNumber() {
  local pattern
  local num
  local -i matches=0
  log_debug "channels=$CHANNELS"

  [[ -f "${CHANNELS}" ]] || touch "${CHANNELS}"

  # shellcheck disable=2001
  pattern=$(echo "$*" | sed 's/\*/\\*/g')
  num=$(grep -ne "^$pattern\$" "${CHANNELS}" | grep -Eo '^[^:]+')
  matches=$(echo -n "$num" | grep -c '^')

  case ${matches} in
  0) num=0;;
  1) ;;
  *) log_error "There were $matches found for $*"; exit 1;;
  esac

  echo $num
}

readInputM3U() {
  local url="$1"
  $curl -s "${url}" \
    | sed -n -e "${sedscript_filter}" \
    | sed -e "${sedscript_rename}"
}

addchannels()
{
  local service=$1
  local url=$2
  local output=${XMLTV}/${service}.m3u
  local -i channelCount=0

  log_info "Adding $service channels from $url"
  log_debug "output=$output"


  echo "#EXTM3U" > "${TMPFILE}"
  while read -r line ; do
    # shellcheck disable=2001
    channelID=$(echo  "${line}" | sed  's/.*,\(.*\)$/\1/')
    log_debug "Got channelID ${channelID}"
    channel=$(getChannelNumber "${channelID}")
    log_debug "Got channel ${channel}"
    if [[ $channel = 0 ]] ; then
      log_notice "new channel found: ${channelID}"
      echo "${channelID}" >> "${CHANNELS}"
      channel=$(getChannelNumber "${channelID}")
    fi

    # shellcheck disable=2001
    printf '%s\n' "$line" | sed -e "s/tvg-id/tvh-chnum=\"$channel\" &/" >> "${TMPFILE}"

    # Get the next line contaiing the url
    read -r line
    echo "${line}" >> "${TMPFILE}"
    channelCount+=1
  done  < <(readInputM3U "${url}")

  log_info "Found $channelCount channels"
  if [[ ${channelCount} -eq 0 ]] ; then
    log_error "No channels found"
    exit 1
  fi
  cp "${TMPFILE}" "${output}"
}

CHANNELS=${XMLTV}/nord.channels
addchannels nord "${URL}"

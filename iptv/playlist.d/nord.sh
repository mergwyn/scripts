#!/usr/bin/env bash

set -o nounset
set -o errexit
set -o pipefail

LOGLEVEL=${LOGLEVEL:-"INFO"}

# shellcheck disable=1090
source "$(dirname "${0}")"/../../functions/log.sh

XMLTV=/srv/media/xmltv
curl=/opt/puppetlabs/puppet/bin/curl

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
  # shellcheck disable=2001
  pattern=$(echo "$*" | sed 's/\*/\\*/g')
  num=$(grep -ne "^$pattern\$" "${CHANNELS}" | grep -Eo '^[^:]+')
  [[ $num -eq "" ]] && num=0
  echo $num
}

addchannels()
{
  SERVICE=$1
  URL=$2
  OUTPUT=${XMLTV}/${SERVICE}.m3u
  CHANNELS=${XMLTV}/${SERVICE}.channels

  log_info "Adding $SERVICE channels from $URL"
  log_debug "OUTPUT=$OUTPUT"
  log_debug "CHANNELS=$CHANNELS"

  [[ -f "${CHANNELS}" ]] || touch "${CHANNELS}"

  echo "#EXTM3U" > "${OUTPUT}"
  $curl -s "${URL}" \
    | sed -n -e "${sedscript_filter}" \
    | sed -e "${sedscript_rename}" \
    | while read -r line ; do
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
        printf '%s\n' "$line" | sed -e "s/tvg-id/tvh-chnum=\"$channel\" &/" >> "${OUTPUT}"

        # Get the next line contaiing the URL
        read -r line
        echo "${line}" >> "${OUTPUT}"
      done 

  outputLines=$(wc -l "${OUTPUT}" | cut -d ' ' -f 1)
  if [[ ${outputLines} -le 1 ]] ; then
    log_error "Only found ${outputLines} processing $SERVICE"
    exit 1
  fi
}

addchannels nord "${URL}"


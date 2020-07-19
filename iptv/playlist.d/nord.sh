#!/usr/bin/env bash

set -o nounset
#set -o errexit
XMLTV=/srv/media/xmltv
curl=/opt/puppetlabs/puppet/bin/curl

DATA="$(dirname "${0}")"/../iptv_urls
if [[ -f "${DATA}" ]]
then
  # shellcheck disable=1090
  . "${DATA}" 
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
sedscript_filter+='/group-title="UK: International/,+1 d;'
while read -r pattern
do
    sedscript_filter+="/$pattern/,+1 p;"
done <<EOF
group-title=\"UK
EOF

# channels to be mapped
while IFS='~' read -r pattern1 pattern2
do
    sedscript_rename+="s~$pattern1~$pattern2~g;"
done <<EOF
EOF

getChannelNumber()
{
  local pattern
  local num
  # shellcheck disable=2001
  pattern=$(echo "$*" | sed 's/\*/\\*/')
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

  [[ -f "${CHANNELS}" ]] || touch "${CHANNELS}"

  exec > "${OUTPUT}"
  echo "#EXTM3U"
  $curl -s "${URL}" |
  sed -n -e "${sedscript_filter}" |
  sed -e "${sedscript_rename}" |
  while read -r line
  do
    #channelID=$(echo  $line | sed 's/^.*tvg-name="\([^"]*\)\" .*$/\1/')
    # shellcheck disable=2001
    channelID=$(echo  "${line}" | sed  's/.*,\(.*\)$/\1/')
    channel=$(getChannelNumber "${channelID}")
    if [[ $channel = 0 ]] 
    then
      echo "${channelID}" >> "${CHANNELS}"
      channel=$(getChannelNumber "${channelID}")
    fi

    # shellcheck disable=2001
    echo "${line}" |
      sed -e "s/tvg-id/tvh-chnum=\"$channel\" &/" #-e 's/\(group-title=".*\)",/\1|H264-AAC",/'
    read -r line
    echo "${line}"
  done 
}

#echo ${sedscript}

addchannels nord "${URL}"


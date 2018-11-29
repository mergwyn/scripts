#!/bin/bash

set -o nounset
#set -o errexit
XMLTV=/srv/media/xmltv
curl=/opt/puppetlabs/puppet/bin/curl

URL="http://vmdirect.co.uk/get.php?username=hhtzoznu&password=q53UWdm5g&type=m3u_plus&output=ts"

channel=
sedscript_filter=
sedscript_rename=

# channels to filtered
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
tvg-id="" tvg-name="UK :Watch HD 1080\*"~tvg-id="W.uk" tvg-name="Watch"
BBC1 HD~BBC 1 HD
BBC2 HD~BBC 2 HD
:History~History
Invietgation~Investigation
ITV2 ~ITV 2 
ITV3 ~ITV 3 
ITV4 ~ITV 4 
:Nat~Nat
:Sky~Sky
:SYFY~SyFy
:Universal~Universal
:Watch~Watch
bt Sports~BT Sport
bt Sport~BT Sport
BT Sports~BT Sport
BT Sport1~BT Sport 1
uk: ~
UK : ~
UK :~
UK: ~
UK:~
UK ~
FHD : ~
SKY SPORTS~Sky Sports
tvg-id="" tvg-name="BBC NEWS HD 1080\*"~tvg-id="" tvg-name="UK BBC NEWS"
tvg-id="" tvg-name="BBC NEWS HD 1080\*"~tvg-id="" tvg-name="UK BBC NEWS"
tvg-id="" tvg-name="BBC FOUR HD 1080\*"~tvg-id="BBC4.uk" tvg-name="UK BBC 4"
tvg-id="" tvg-name="Channel 4 HD 1080\*"~tvg-id="Channel4.uk" tvg-name="UK Channel 4"
tvg-id="" tvg-name="Channel 5 HD 1080\*"~tvg-id="Channel5.uk" tvg-name="UK Channel 5"
tvg-id="" tvg-name="E4 HD 1080\*"~tvg-id="E4.uk" tvg-name="UK E4"
tvg-id="" tvg-name="Film4 HD 1080\*"~tvg-id="Film4.uk" tvg-name="UK Film 4"
tvg-id="" tvg-name="More4 HD 1080\*"~tvg-id="More4.uk" tvg-name="More 4"
tvg-id="" tvg-name="Sky Cinema Action & Adventure HD 1080\*"~tvg-id="SkyMoviesActionThriller.uk" tvg-name="Sky Movies Action and Adventure HD"
tvg-id="" tvg-name="Sky Cinema Comedy HD 1080\*"~tvg-id="SkyMoviesComedy.uk" tvg-name="Sky Movies Comedy HD"
tvg-id="" tvg-name="Sky Cinema Crime & Thriller HD 1080\*"~tvg-id="SkyCinemaThriller.uk" tvg-name="Sky Movies Crime and Thriller HD"
tvg-id="" tvg-name="Sky Cinema Disney HD 1080\*"~tvg-id="SkyMoviesDisney.uk" tvg-name="Sky Movies Disney HD"
tvg-id="" tvg-name="Sky Cinema Drama & Romance HD 1080\*"~tvg-id="SkyMoviesDrama.uk" tvg-name="Sky Movies Drama and Romance HD"
tvg-id="" tvg-name="Sky Cinema Family HD 1080\*"~tvg-id="SkyMoviesFamily.uk" tvg-name="Sky Movies Family HD"
tvg-id="" tvg-name="Sky Cinema Greats HD 1080\*"~tvg-id="Sky Movies Greats UK" tvg-name="Sky Movies Modern Greats HD"
tvg-id="" tvg-name="Sky Cinema Hits HD 1080\*"~tvg-id="SkyCinemaHits.uk " tvg-name="Sky Cinema Hits HD"
tvg-id="" tvg-name="Sky Cinema Premiere HD 1080\*"~tvg-id="SkyMoviesPremiere.uk" tvg-name="Sky Movies Premiere HD 1080\*"
tvg-id="" tvg-name="Sky Cinema Sci-Fi & Horror HD 1080\*"~tvg-id="SkySciFiHorror.uk" tvg-name="Sky Movies Sci-Fi Horror HD"
tvg-id="" tvg-name="Sky Cinema Select HD 1080\*"~tvg-id="Sky Cinema Select UK" tvg-name="Sky Movies Select HD"
tvg-id="" tvg-name="BBC NEWS"~tvg-id="" tvg-name="UK BBC NEWS"
tvg-id="" tvg-name="sky 1 HD 1080\*"~tvg-id="Sky1.uk" tvg-name="Sky 1" 
tvg-id="" tvg-name="SYFY HD 1080\*"~tvg-id="SCIFI.uk" tvg-name="SyFy"
tvg-id="" tvg-name="Universal Channel HD 1080\*"~tvg-id="" tvg-name="Universal"
tvg-id="" tvg-name="BT Sport ESPN 1080\*"~tvg-id="BTSportESPN.uk" tvg-name="BT Sport / ESPN 1080*"
tvg-id="" tvg-name="BT Sport 3 FHD 1080"~tvg-id="BTSport3.uk" tvg-name="BT Sport 3 FHD 1080"
tvg-id="" tvg-name="BT Sport 1 FHD 1080\*"~tvg-id="BTSport1.uk" tvg-name="BT Sport 1 FHD 1080*"
EOF

getChannelNumber()
{
  local pattern=$(echo "$*" | sed 's/\*/\\*/')
  local num=$(grep -ne "^$pattern\$" ${CHANNELS} | grep -Eo '^[^:]+')
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

  exec > $OUTPUT
  echo "#EXTM3U"
  $curl -s "${URL}" |
  sed '/#EXTM3U/d' |
  sed -n -e "${sedscript_filter}" |
  sed -e "${sedscript_rename}" |
  while read line
  do
    #channelID=$(echo  $line | sed 's/^.*tvg-name="\([^"]*\)\" .*$/\1/')
    channelID=$(echo  $line | sed  's/.*,\(.*\)$/\1/')
    channel=$(getChannelNumber "${channelID}")
    if [[ $channel = 0 ]] 
    then
      echo ${channelID} >> ${CHANNELS}
      channel=$(getChannelNumber "${channelID}")
    fi

    echo $line |
      sed -e "s/tvg-id/tvh-chnum=\"$channel\" &/" -e 's/\(group-title=".*\)",/\1|H264-AAC",/'
    read line
    echo $line
  done 
}

#echo ${sedscript}

addchannels magic $URL

# vim: nu sw=2 ai

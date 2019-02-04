#!/bin/bash

#set -o nounset
#set -o errexit

DATA="$(dirname $0)/../iptv_urls"
if [[ -f ${DATA} ]]
then
  . ${DATA}
else
  echo "URL file ${DATA} not found" >&2
  exit 1
fi

SERVICE=magic
URL=${MAGIC_EPG}

XMLTV=/srv/media/xmltv
tvhsock=/var/lib/hts/.hts/tvheadend/epggrab/xmltv.sock
curl=/opt/puppetlabs/puppet/bin/curl
xmllint=/opt/puppetlabs/puppet/bin/xmllint

OUTPUT=${XMLTV}/${SERVICE}.xml

${curl} -s "${URL}"  | ${xmllint} --format - >  ${OUTPUT}

socat FILE:${OUTPUT} UNIX-CONNECT:${tvhsock} 

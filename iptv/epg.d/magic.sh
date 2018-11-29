#!/bin/bash

#set -o nounset
#set -o errexit

SERVICE=magic
URL='http://thebesthost.uk//xmltv.php?username=hhtzoznu&password=q53UWdm5g'

XMLTV=/srv/media/xmltv
tvhsock=/var/lib/hts/.hts/tvheadend/epggrab/xmltv.sock
curl=/opt/puppetlabs/puppet/bin/curl
xmllint=/opt/puppetlabs/puppet/bin/xmllint

OUTPUT=${XMLTV}/${SERVICE}.xml

${curl} -s "${URL}"  | ${xmllint} --format - >  ${OUTPUT}

socat FILE:${OUTPUT} UNIX-CONNECT:${tvhsock} 

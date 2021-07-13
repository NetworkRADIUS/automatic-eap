#!/bin/bash
# Copyright 2021 NetworkRADIUS SARL (legal@networkradius.com)
# Author: Jorge Pereira <jpereira@freeradius.org>
#

RADDIR="/etc/freeradius"
IPADDR=$(hostname -i)

#
#  Handle clients{} entries
#
if [ -n "${RADIUS_CLIENTS}" ]; then
  for _c in ${RADIUS_CLIENTS}; do
    _name="$(echo $_c | cut -f1 -d '|')"
    _ipaddr="$(echo $_c | cut -f2 -d '|')"
    _secret="$(echo $_c | cut -f3 -d '|')"

    cat >> ${RADDIR}/clients.conf <<EOF

# Added client over Docker 'RADIUS_CLIENT' env.
client ${_name} {
  ipaddr = ${_ipaddr}
  secret = ${_secret}
}
EOF
  done
fi

# Start FreeRADIUS
echo "Starting FreeRADIUS..."

if [ "$#" -gt 0 ]; then
  exec /usr/sbin/freeradius "$@"
else
  exec /usr/sbin/freeradius -X
fi

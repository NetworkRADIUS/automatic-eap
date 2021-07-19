#!/bin/bash
# Copyright 2021 NetworkRADIUS SARL (legal@networkradius.com)
# Author: Jorge Pereira <jpereira@freeradius.org>
#

IPADDR=$(hostname -i)

mkdir -p /etc/powerdns/pdns.d

# bootstrap
rm -f /etc/powerdns/powerdns.sqlite3
sqlite3 /etc/powerdns/powerdns.sqlite3 < /usr/share/doc/pdns-backend-sqlite3/schema.sqlite3.sql

if [ -z "${DOMAIN}" ]; then
  echo "ERROR: We can't continue without DOMAIN=... env"
  exit 1
fi
pdnsutil create-zone "${DOMAIN}"
pdnsutil add-record "${DOMAIN}" . A ${IPADDR}

if [ -z "${DNS_RECORDS}" ]; then
  echo "ERROR: We can't continue without DNS_RECORDS=\"entry1 entryN ...\" env"
  exit 1
fi
for _record in ${DNS_RECORDS[*]}; do
  _entry="$(echo ${_record} | cut -f1 -d '|')"
  _ipaddr="$(echo ${_record} | cut -f2 -d '|')"

  [ -z "${_ipaddr}" ] && _ipaddr="${IPADDR}"

  pdnsutil add-record ${DOMAIN} ${_entry} A ${_ipaddr}
done

#
# cert ca/server entries
#
if [ -z "${DNS_CERT_CA_PATH}" ]; then
  echo "ERROR: We can't continue without DNS_CERT_CA_PATH=\"http://host.com/path/cert\" env"
  exit 1
fi
pdnsutil add-record ${DOMAIN} _ca._cert._eap CERT "4 0 0 $(echo -n ${DNS_CERT_CA_PATH} | base64)"

if [ -z "${DNS_CERT_SERVER_PATH}" ]; then
  echo "ERROR: We can't continue without DNS_CERT_SERVER_PATH=\"http://host.com/path/cert\" env"
  exit 1
fi
pdnsutil add-record ${DOMAIN} _server._cert._eap CERT "4 0 0 $(echo -n ${DNS_CERT_SERVER_PATH} | base64)"

echo "-----------------------------------------------------"
pdnsutil list-zone ${DOMAIN}
echo "-----------------------------------------------------"
#
# Start PowerDNS
# same as /etc/init.d/pdns monitor
#
echo "Starting PowerDNS..."

if [ "$#" -gt 0 ]; then
  exec /usr/sbin/pdns_server "$@"
else
  exec /usr/sbin/pdns_server --daemon=no --guardian=no --control-console --loglevel=9
fi

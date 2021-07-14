#!/bin/bash
# Copyright 2021 NetworkRADIUS SARL (legal@networkradius.com)
# Author: Jorge Pereira <jpereira@freeradius.org>
#

NGINX="/etc/nginx"
IPADDR=$(hostname -i)

# Start NGINX
echo "Starting NGINX..."

if [ "$#" -gt 0 ]; then
  exec /usr/sbin/nginx "$@"
else
  exec /usr/sbin/nginx -g "daemon off;"
fi

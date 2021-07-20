#
#  Copyright 2021 NetworkRADIUS SARL (legal@networkradius.com)
#
#MAINTAINER NetworkRADIUS <support@networkradius.com>

ARG from=networkradius/automatic-eap:ubuntu20-deps
FROM ${from}

SHELL ["/usr/bin/nice", "-n", "5", "/usr/bin/ionice", "-c", "3", "/bin/sh", "-x", "-c"]

ARG APT_OPTS="-y --option=Dpkg::options::=--force-unsafe-io --no-install-recommends"
ARG DEBIAN_FRONTEND=noninteractive

#
# install nginx package
#
RUN apt-get -y update && \
	apt-get -y install nginx

WORKDIR /etc/nginx

#
#  Overwrite the /etc/nginx using our own config files.
#

# Certificates
RUN mkdir -p /var/www/html/.well-known/est/
ADD certs/ca.pem \
	/var/www/html/.well-known/est/cacerts

RUN mkdir -p /var/www/html/.well-known/eap/
ADD certs/server.pem \
	/var/www/html/.well-known/eap/server

RUN chmod 0644 /var/www/html/.well-known/eap/server \
               /var/www/html/.well-known/est/cacerts

# Update the index.html
ADD docker/server/nginx/index.html /var/www/html/index.html

# Start scripts
ADD docker/server/nginx/start.sh /usr/local/bin/start.sh
RUN chmod a+x /usr/local/bin/*.sh

EXPOSE 80:80/tcp

CMD ["/usr/local/bin/start.sh"]

#
#  Copyright 2021 NetworkRADIUS SARL (legal@networkradius.com)
#
#MAINTAINER NetworkRADIUS <support@networkradius.com>

ARG from=networkradius/automatic-eap:ubuntu20-deps
FROM ${from}

SHELL ["/usr/bin/nice", "-n", "5", "/usr/bin/ionice", "-c", "3", "/bin/sh", "-x", "-c"]

ARG from=networkradius/ubuntu20-deps
ARG dh_key_size=2048

ARG APT_OPTS="-y --option=Dpkg::options::=--force-unsafe-io --no-install-recommends"
ARG DEBIAN_FRONTEND=noninteractive

#
# install PowerDNS package
#
#COPY docker/server/dns/pdns.list /etc/apt/sources.list.d/pdns.list
#ADD docker/server/dns/pdns.preference /etc/apt/preferences.d/pdns 
#RUN curl https://repo.powerdns.com/FD380FBB-pub.asc | apt-key add -

RUN apt-get -y update && \
	apt-get -y install pdns-server pdns-recursor pdns-tools pdns-backend-sqlite3 sqlite3

COPY docker/server/dns/config/ /etc/powerdns/

ADD docker/server/dns/start.sh /usr/local/bin/start.sh
RUN chmod a+x /usr/local/bin/*.sh

EXPOSE 53/udp

CMD ["/usr/local/bin/start.sh"]


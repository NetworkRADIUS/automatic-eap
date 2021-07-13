#
#  Copyright 2021 NetworkRADIUS SARL (legal@networkradius.com)
#
#MAINTAINER NetworkRADIUS <support@networkradius.com>

ARG from=freeradius/automatic-eap:ubuntu20-deps
FROM ${from}

SHELL ["/usr/bin/nice", "-n", "5", "/usr/bin/ionice", "-c", "3", "/bin/sh", "-x", "-c"]

ARG from=freeradius/ubuntu20-deps
ARG dh_key_size=2048

ARG APT_OPTS="-y --option=Dpkg::options::=--force-unsafe-io --no-install-recommends"
ARG DEBIAN_FRONTEND=noninteractive

#
# install freeradius package
#
RUN apt-get -y update && \
	apt-get -y install freeradius

WORKDIR /etc/freeradius
RUN sed -i -e 's/allow_vulnerable_openssl.*/allow_vulnerable_openssl = yes/' radiusd.conf
RUN make -C certs DH_KEY_SIZE=$dh_key_size

#
#  Overwrite the /etc/freeradius using our own config files.
#
ADD docker/server/radius/config/etc/freeradius/ /etc/freeradius/
ADD docker/server/radius/start.sh /usr/local/bin/start.sh
RUN chmod a+x /usr/local/bin/*.sh

EXPOSE 1812:1812/udp 1813:1813/udp

CMD ["/usr/local/bin/start.sh"]

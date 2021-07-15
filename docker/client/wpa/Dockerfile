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
	apt-get -y install wpasupplicant libssl-dev python3-pip

#
#  install eapol_test
#
WORKDIR /tmp
RUN wget -O - https://w1.fi/releases/wpa_supplicant-2.9.tar.gz | tar -xzf -
ADD docker/client/wpa/config_linux /tmp/wpa_supplicant-2.9/wpa_supplicant/.config
WORKDIR /tmp/wpa_supplicant-2.9/wpa_supplicant
RUN	make -j4 eapol_test && cp eapol_test /usr/local/bin/eapol_test && rm -rf /tmp/wpa_supplicant-2.9/
RUN rm -rf /tmp/wpa_supplicant-2.9/wpa_supplicant

#
# Automatic-EAP Script dependencies
#
ADD docker/client/automatic-eap/requirements.txt /tmp
RUN pip3 install -r /tmp/requirements.txt && rm -f /tmp/requirements.txt

#
# Automatic-EAP Script
#
ADD docker/client/automatic-eap/automatic-eap.py /usr/local/bin/
RUN chmod +x /usr/local/bin/automatic-eap.py

#
#  Client
#

CMD ["/bin/bash"]

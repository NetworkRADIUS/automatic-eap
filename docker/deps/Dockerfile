#
#  Copyright 2021 NetworkRADIUS SARL (legal@networkradius.com)
#
#MAINTAINER NetworkRADIUS <support@networkradius.com>

ARG from=ubuntu:20.04
FROM ${from}

SHELL ["/usr/bin/nice", "-n", "5", "/usr/bin/ionice", "-c", "3", "/bin/sh", "-x", "-c"]

ARG osname=focal
ONBUILD ARG osname=${osname}

ARG APT_OPTS="-y --option=Dpkg::options::=--force-unsafe-io --no-install-recommends"
ARG DEBIAN_FRONTEND=noninteractive

#
#  It must have...
#
RUN apt-get update && \
#  Development utilities
    apt-get install $APT_OPTS \
    	apt-utils \
        bind9-dnsutils \
        devscripts \
        equivs \
        git \
        gnupg2 \
        lsb-release \
        procps \
        quilt \
        rsync \
        software-properties-common \
        wget \
        lynx \
        sudo \
        curl \
        net-tools \
        tcpdump \
        iputils-ping \
#  eapol_test dependencies
        libnl-3-dev \
        libnl-genl-3-dev \
#  For debugging (e.g. in crossbuild)
        gdb \
        less \
        vim \
#  Compilers
        clang \
        g++ \
        lldb \
        llvm

#
#  Oficial FreeRADIUS package repo
#
ADD docker/deps/networkradius.list /etc/apt/sources.list.d/networkradius.list
RUN curl -s 'https://packages.networkradius.com/pgp/packages%40networkradius.com' | \
        sudo apt-key add -

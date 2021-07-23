#
#  Copyright 2021 NetworkRADIUS SARL (legal@networkradius.com)
#

# DNS settings
DOMAIN := example.com
DNS_RECORDS := www certs foo|192.168.10.55 bar|192.168.10.52
DNS_CERT_CA_PATH := http://certs.example.com/.well-known/est/cacerts
DNS_CERT_SERVER_PATH := http://certs.example.com/.well-known/eap/server

# don't touch here
DOCKER_IMAGE_HUB := networkradius
DOCKER_IMAGE_NAME := $(DOCKER_IMAGE_HUB)/automatic-eap

# Lookup the docker subnet
DOCKER_SUBNET := $(shell docker network inspect --format='{{range .IPAM.Config}}{{.Subnet}}{{end}}' bridge)

# RADIUS Settings
RADIUS_CLIENTS := "DockerSubnet01|$(DOCKER_SUBNET)|testing123"

#
#  You can watch what it's doing by:
#
#	$ VERBOSE=1 make ... args ...
#
ifeq "${VERBOSE}" ""
    Q=@
    DEST=1> /dev/null 2>&1
else
    Q=
    DEST=
endif

.PHONY = deps
# Test if the dependencies we need to run this Makefile are installed
DOCKER := $(shell which docker 1> /dev/null 2>&1)
deps:
ifndef DOCKER
	@echo "Docker is not available. Please install docker"
	@exit 1
endif

.PHONY: help
help:
	@echo "help               - print this."
	@echo "docker.server.run  - Build and start up the servers containers."
	@echo "docker.server.stop - Stop all servers containers."
	@echo "docker.client.run  - Build and start up the client instance."
	@echo "destroy            - Delete all instances and created images."
	@echo "clean.docker       - Just remove all started instances."
	@echo "build.certs        - Build the certificates in certs/."
	@echo "clean.certs        - Clean up the created certificates in certs/"
	@echo
	@echo "  Use the Q= if you want to see the logs"

.DEFAULT_GOAL := help

ifeq "$(DOMAIN)" ""
	$(error We can't go without the DOMAIN=... parameter)
endif

#
#  Clean & Destroy
#
clean: help

clean.docker.stop.%:
	@echo "Stopping Docker automatic-eap-$*"
	$(Q)docker stop automatic-eap-$* $(DEST)

clean.docker.instance.%:
	$(Q)docker rm -f automatic-eap-$* $(DEST)

clean.docker.instances: clean.docker.instance.client clean.docker.instance.server-radius clean.docker.instance.server-dns clean.docker.instance.server-www

clean.docker.image.%:
	$(Q)docker rmi -f $(DOCKER_IMAGE_NAME):$* $(DEST)

clean.docker.images: clean.docker.image.client clean.docker.image.server-radius clean.docker.image.server-dns clean.docker.image.server-www clean.docker.image.ubuntu20-deps

destroy: clean.docker.instances clean.docker.images clean.certs
	$(Q)rm -rf build

clean.docker: clean.certs clean.docker.instances

#
#  Certificates
#
certs/%.cnf:
	$(Q)sed "s/@@DOMAIN@@/$(DOMAIN)/g" < certs/$*.cnf.tpl > certs/$*.cnf

clean.certs:
	$(Q)touch certs/client.cnf certs/server.cnf # Needed by certs/Makefile
	$(Q)make -C certs/ destroycerts

build.certs: certs/client.cnf certs/server.cnf
	@echo "Build the certificates"
	$(Q)make -C certs/ DH_KEY_SIZE=2048 all $(DEST)

#
#  Docker Build
#
build/docker.deps:
	$(Q)docker build . -f docker/deps/Dockerfile -t $(DOCKER_IMAGE_NAME):ubuntu20-deps $(DEST)
	$(Q)mkdir -p $(dir $@)
	$(Q)touch $@

docker.build.%: build.certs build/docker.deps
	@echo "Build Docker server-$*"
	$(Q)docker build . -f docker/server/$*/Dockerfile -t $(DOCKER_IMAGE_NAME):server-$* $(DEST)

#
#  Radius
#
docker.radius.run: clean.docker.instance.server-radius docker.build.radius
	@echo "Start Docker RADIUS Server"
	$(Q)docker run -dit --name automatic-eap-server-radius --hostname automatic-eap-server-radius \
		-e RADIUS_CLIENTS=$(RADIUS_CLIENTS) \
		-p 1812-1813:1812-1813/udp $(DOCKER_IMAGE_NAME):server-radius $(DEST)

#
#  Dns
#
docker.dns.run: clean.docker.instance.server-dns docker.build.dns
	@echo "Start Docker DNS Server"
	$(eval DOCKER_WWW_IP = $(shell docker inspect -f '{{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}}' automatic-eap-server-www))
	$(eval DNS_RECORDS += certs|$(DOCKER_WWW_IP) www|$(DOCKER_WWW_IP)) # Create the dns records pointing to the www container
	$(Q)docker run -dit --name automatic-eap-server-dns --hostname automatic-eap-server-dns \
		-e DOMAIN="$(DOMAIN)" \
		-e DNS_RECORDS="$(DNS_RECORDS)" \
		-e DNS_CERT_CA_PATH="$(DNS_CERT_CA_PATH)" \
		-e DNS_CERT_SERVER_PATH="$(DNS_CERT_SERVER_PATH)" \
		-p 53:53/udp $(DOCKER_IMAGE_NAME):server-dns $(DEST)

#
#  wwww
#
docker.www.run: clean.docker.instance.server-www docker.build.www
	@echo "Start Docker WWW Server"
	$(Q)docker run -dit --name automatic-eap-server-www --hostname automatic-eap-server-www \
		-p 80:80/tcp $(DOCKER_IMAGE_NAME):server-www $(DEST)

#
#  Server Run
#
docker.server.run: docker.radius.run docker.www.run docker.dns.run

docker.server.stop: clean.docker.stop.server-radius clean.docker.stop.server-dns clean.docker.stop.server-www

#
#  Client automatic-eap.py & eapol_test
#
docker.client:
	$(Q)docker build . -f docker/client/automatic-eap/Dockerfile -t $(DOCKER_IMAGE_NAME):client $(DEST)

docker.client.run: clean.docker.instance.client docker.server.run docker.client
	@echo "Start Docker Client"
	$(eval DOCKER_DNS_IP = $(shell docker inspect -f '{{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}}' automatic-eap-server-dns))
	$(eval DOCKER_RADIUS_IP = $(shell docker inspect -f '{{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}}' automatic-eap-server-radius))
	$(Q)docker run -it --rm --name automatic-eap-client --hostname automatic-eap-client \
		--dns $(DOCKER_DNS_IP) \
		-e DOMAIN="$(DOMAIN)" \
		-e DNS_IP="$(DOCKER_DNS_IP)" \
		-e RADIUS_IP=$(DOCKER_RADIUS_IP) \
		$(DOCKER_IMAGE_NAME):client

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
else
    Q=
endif

.PHONY = deps
# Test if the dependencies we need to run this Makefile are installed
DOCKER := $(shell which daaocker 1> /dev/null 2>&1)
deps:
ifndef DOCKER
	@echo "Docker is not available. Please install docker"
	@exit 1
endif

.PHONY: help
help:
	@echo "help            - print this"
	@echo "docker.deps     - Build the 'deps' container image"
	@echo "docker.radius   - Build the 'radius' container image"
	@echo "docker.dns      - Build the 'dns' container image"
	@echo "docker.www      - Build the 'www' container image"

.DEFAULT_GOAL := help

ifeq "$(DOMAIN)" ""
	$(error We can't go without the DOMAIN=... parameter)
endif

docker: docker.radius docker.dns

#
#  Deps
#
docker.deps: build.certs
	$(Q)docker build . -f docker/deps/Dockerfile -t $(DOCKER_IMAGE_NAME):ubuntu20-deps

#
#  Certificates
#
certs/client.cnf:
	$(Q)sed "s/@@DOMAIN@@/$(DOMAIN)/g" < certs/client.cnf.tpl > certs/client.cnf

certs/server.cnf:
	$(Q)sed "s/@@DOMAIN@@/$(DOMAIN)/g" < certs/server.cnf.tpl > certs/server.cnf

build.certs: certs/client.cnf certs/server.cnf
	$(Q)make -C certs/ DH_KEY_SIZE=2048 all

clean.certs.cnf:
	$(Q)rm -f certs/server.cnf certs/client.cnf

clean.certs: clean.certs.cnf certs/client.cnf certs/server.cnf
	$(Q)make -C certs/ destroycerts

#
#  Radius
#
docker.radius: docker.deps
	$(Q)docker build . -f docker/server/radius/Dockerfile -t $(DOCKER_IMAGE_NAME):service-radius

docker.radius.run: docker.radius
	$(Q)docker rm -f service-radius
	$(Q)docker run -dit --name service-radius --hostname service-radius \
		-e RADIUS_CLIENTS=$(RADIUS_CLIENTS) \
		-p 1812-1813:1812-1813/udp $(DOCKER_IMAGE_NAME):service-radius

#
#  Dns
#
docker.dns: docker.deps
	$(eval DOCKER_WWW_IP = $(shell docker inspect -f '{{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}}' service-www))
	$(eval DNS_RECORDS += certs|$(DOCKER_WWW_IP) www|$(DOCKER_WWW_IP)) # Create the dns records pointing to the www container
	$(Q)docker build . -f docker/server/powerdns/Dockerfile -t $(DOCKER_IMAGE_NAME):service-dns

docker.dns.run: docker.dns docker.www.run
	$(Q)docker rm -f service-dns
	$(Q)docker run -dit --name service-dns --hostname service-dns \
		-e DOMAIN="$(DOMAIN)" \
		-e DNS_RECORDS="$(DNS_RECORDS)" \
		-e DNS_CERT_CA_PATH="$(DNS_CERT_CA_PATH)" \
		-e DNS_CERT_SERVER_PATH="$(DNS_CERT_SERVER_PATH)" \
		-p 53:53/udp $(DOCKER_IMAGE_NAME):service-dns

#
#  wwww
#
docker.www: docker.deps
	$(Q)docker build . -f docker/server/nginx/Dockerfile -t $(DOCKER_IMAGE_NAME):service-www

docker.www.run: docker.www
	$(Q)docker rm -f service-www
	$(Q)docker run -dit --name service-www --hostname service-www \
		-p 80:80/tcp $(DOCKER_IMAGE_NAME):service-www

#
#  Clean
#
destroy:
	$(Q)docker rmi -f $(DOCKER_IMAGE_NAME):service-dns \
						$(DOCKER_IMAGE_NAME):service-www \
						$(DOCKER_IMAGE_NAME):service-radius \
						$(DOCKER_IMAGE_NAME):client \
						$(DOCKER_IMAGE_NAME):ubuntu20-deps

clean.docker: clean.certs clean.docker.radius clean.docker.dns clean.docker.www

clean.docker.radius:
	$(Q)docker rm -f service-radius

clean.docker.dns:
	$(Q)docker rm -f service-dns

clean.docker.www:
	$(Q)docker rm -f service-www

docker.server.run: docker.radius.run docker.dns.run docker.www.run

#
#  Client automatic-eap.py & eapol_test
#
docker.client.eapol_test:
	$(Q)docker build . -f docker/client/automatic-eap/Dockerfile -t $(DOCKER_IMAGE_NAME):client

docker.client.run: docker.client.eapol_test docker.server.run
	$(eval DOCKER_DNS_IP = $(shell docker inspect -f '{{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}}' service-dns))
	$(eval DOCKER_RADIUS_IP = $(shell docker inspect -f '{{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}}' service-radius))
	$(Q)docker run -it --rm --name client --hostname automatic-eap-client \
		--dns $(DOCKER_DNS_IP) \
		-e DOMAIN="$(DOMAIN)" \
		-e DNS_IP="$(DOCKER_DNS_IP)" \
		-e RADIUS_IP=$(DOCKER_RADIUS_IP) \
		-e DNS_IP=$(DOCKER_DNS_IP) \
		$(DOCKER_IMAGE_NAME):client

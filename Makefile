#
#  Copyright 2021 NetworkRADIUS SARL (legal@networkradius.com)
#

DOCKER_IMAGE_HUB := networkradius
DOCKER_IMAGE_ROOT := $(DOCKER_IMAGE_HUB)/automatic-eap
DOCKER_SUBNET := $(shell docker network inspect --format='{{range .IPAM.Config}}{{.Subnet}}{{end}}' bridge)

# RADIUS Settings
RADIUS_CLIENTS := "DockerSubnet01|$(DOCKER_SUBNET)|testing123"

# DNS settings
DOMAIN := example.com
DNS_RECORDS := www certs foo|192.168.10.55 bar|192.168.10.52
DNS_CERT_CA_PATH := http://certs.example.com/.well-known/est/cacerts
DNS_CERT_SERVER_PATH := http://certs.example.com/.well-known/eap/server

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

all:
	@echo "help            - print this"
	@echo "docker.deps     - Build the 'deps' container image"
	@echo "docker.radius   - Build the 'radius' container image"
	@echo "docker.dns      - Build the 'dns' container image"
	@echo "docker.www      - Build the 'www' container image"

ifeq "$(DOMAIN)" ""
	$(error We can't go without the DOMAIN=... parameter)
endif

docker: docker.radius docker.dns

#
#  Deps
#
docker.deps: build.certs
	$(Q)docker build . -f docker/deps/Dockerfile -t $(DOCKER_IMAGE_ROOT):ubuntu20-deps

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
	$(Q)docker build . -f docker/server/radius/Dockerfile -t $(DOCKER_IMAGE_ROOT):service-radius

docker.radius.run: docker.radius
	$(Q)docker run -dit --name service-radius \
		-e RADIUS_CLIENTS=$(RADIUS_CLIENTS) \
		-p 1812-1813:1812-1813/udp $(DOCKER_IMAGE_ROOT):service-radius

#
#  Dns
#
docker.dns: docker.deps
	$(Q)docker build . -f docker/server/powerdns/Dockerfile -t $(DOCKER_IMAGE_ROOT):service-dns

docker.dns.run: docker.dns docker.www.run
	$(Q)docker run -dit --name service-dns \
		-e DOMAIN="$(DOMAIN)" \
		-e DNS_RECORDS="$(DNS_RECORDS)" \
		-e DNS_CERT_CA_PATH="$(DNS_CERT_CA_PATH)" \
		-e DNS_CERT_SERVER_PATH="$(DNS_CERT_SERVER_PATH)" \
		-p 53:53/udp $(DOCKER_IMAGE_ROOT):service-dns

#
#  wwww
#
docker.www: docker.deps
	$(Q)docker build . -f docker/server/nginx/Dockerfile -t $(DOCKER_IMAGE_ROOT):service-www

docker.www.run: docker.www
	$(Q)docker run -dit --name service-www \
		-e DOMAIN="$(DOMAIN)" \
		-e DNS_RECORDS="$(DNS_RECORDS)" \
		-e DNS_CERT_CA_PATH="$(DNS_CERT_CA_PATH)" \
		-e DNS_CERT_SERVER_PATH="$(DNS_CERT_SERVER_PATH)" \
		-p 80:80/tcp $(DOCKER_IMAGE_ROOT):service-www

#
#  Clean
#
clean.docker: clean.certs clean.docker.radius clean.docker.dns clean.docker.www

clean.docker.radius:
	$(Q)docker rm -f service-radius

clean.docker.dns:
	$(Q)docker rm -f service-dns

clean.docker.www:
	$(Q)docker rm -f service-www

docker.server.run: clean.docker docker.radius.run docker.dns.run docker.www.run

#
#  Client WPA
#
docker.client.wpa:
	$(Q)docker build . -f docker/client/wpa/Dockerfile -t $(DOCKER_IMAGE_ROOT):client-wpa

docker.client.run: docker.client.wpa
	$(Q)docker run -it --rm --name client-wpa \
		-e DOMAIN="$(DOMAIN)" \
		-e DNS_RECORDS="$(DNS_RECORDS)" \
		-e DNS_CERT_CA_PATH="$(DNS_CERT_CA_PATH)" \
		-e DNS_CERT_SERVER_PATH="$(DNS_CERT_SERVER_PATH)" \
		$(DOCKER_IMAGE_ROOT):client-wpa

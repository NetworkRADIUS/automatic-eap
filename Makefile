#
#  Copyright 2021 NetworkRADIUS SARL (legal@networkradius.com)
#

DOCKER_IMAGE := freeradius
DOCKER_IMAGE_DEPS := $(DOCKER_IMAGE)/automatic-eap
DOCKER_SUBNET := $(shell docker network inspect --format='{{range .IPAM.Config}}{{.Subnet}}{{end}}' bridge)

# RADIUS Settings
RADIUS_CLIENTS := "DockerSubnet01|$(DOCKER_SUBNET)|testing123"

# DNS settings
DNS_ZONE := example.com
DNS_RECORDS := foo|192.168.10.55 bar|192.168.10.52
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

docker: docker.radius docker.dns

#
#  Deps
#
docker.deps: build.certs
	$(Q)docker build . -f docker/deps/Dockerfile -t $(DOCKER_IMAGE_DEPS):ubuntu20-deps

#
#  Certificates
#
build.certs:
	$(Q)make -C docker/server/radius/config/etc/freeradius/certs/ DH_KEY_SIZE=2048 all

build.certs.clean:
	$(Q)make -C docker/server/radius/config/etc/freeradius/certs/ destroycerts

#
#  Radius
#
docker.radius: docker.deps
	$(Q)docker build . -f docker/server/radius/Dockerfile -t $(DOCKER_IMAGE_DEPS):service-radius

docker.radius.run: docker.radius
	$(Q)docker run -dit --name service-radius \
		-e RADIUS_CLIENTS=$(RADIUS_CLIENTS) \
		-p 1812-1813:1812-1813/udp freeradius/automatic-eap:service-radius

#
#  Dns
#
docker.dns: docker.deps
	$(Q)docker build . -f docker/server/powerdns/Dockerfile -t $(DOCKER_IMAGE_DEPS):service-dns

docker.dns.run: docker.dns docker.www.run
	$(eval DOCKER_WWW_IP = $(shell docker inspect -f '{{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}}' service-www))
	$(eval DNS_RECORDS += certs|$(DOCKER_WWW_IP) www|$(DOCKER_WWW_IP))
	$(Q)docker run -dit --name service-dns \
		-e DNS_ZONE="$(DNS_ZONE)" \
		-e DNS_RECORDS="$(DNS_RECORDS)" \
		-e DNS_CERT_CA_PATH="$(DNS_CERT_CA_PATH)" \
		-e DNS_CERT_SERVER_PATH="$(DNS_CERT_SERVER_PATH)" \
		-p 53:53/udp freeradius/automatic-eap:service-dns

#
#  wwww
#
docker.www: docker.deps
	$(Q)docker build . -f docker/server/nginx/Dockerfile -t $(DOCKER_IMAGE_DEPS):service-www

docker.www.run: docker.www
	$(Q)docker run -dit --name service-www \
		-e DNS_ZONE="$(DNS_ZONE)" \
		-e DNS_RECORDS="$(DNS_RECORDS)" \
		-e DNS_CERT_CA_PATH="$(DNS_CERT_CA_PATH)" \
		-e DNS_CERT_SERVER_PATH="$(DNS_CERT_SERVER_PATH)" \
		-p 80:80/tcp freeradius/automatic-eap:service-www

#
#  Client WPA
#
docker.client.wpa:
	$(Q)docker build . -f docker/client/wpa/Dockerfile -t $(DOCKER_IMAGE_DEPS):client-wpa

docker.client.run: docker.client.wpa
	$(Q)docker run -it --rm --name client-wpa \
		-e DNS_ZONE="$(DNS_ZONE)" \
		-e DNS_RECORDS="$(DNS_RECORDS)" \
		-e DNS_CERT_CA_PATH="$(DNS_CERT_CA_PATH)" \
		-e DNS_CERT_SERVER_PATH="$(DNS_CERT_SERVER_PATH)" \
		freeradius/automatic-eap:client-wpa

#
#  Clean
#
docker.clean: build.certs.clean docker.radius.clean docker.dns.clean docker.www.clean

docker.radius.clean:
	$(Q)docker rm -f service-radius

docker.dns.clean:
	$(Q)docker rm -f service-dns

docker.www.clean:
	$(Q)docker rm -f service-www

docker.server.run: docker.clean docker.radius.run docker.dns.run docker.www.run

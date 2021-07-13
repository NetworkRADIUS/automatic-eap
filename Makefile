#
#  Copyright 2021 NetworkRADIUS SARL (legal@networkradius.com)
#

DOCKER_IMAGE := freeradius
DOCKER_IMAGE_DEPS := $(DOCKER_IMAGE)/automatic-eap
DOCKER_SUBNET := $(shell docker network inspect --format='{{range .IPAM.Config}}{{.Subnet}}{{end}}' bridge)

# RADIUS Settings
RADIUS_CLIENTS := "DockerSubnet01|$(DOCKER_SUBNET)|testing123"

# DNS settings
DNS_ZONE := "example.com"
DNS_RECORDS := "www ftp|192.168.10.55"
DNS_CERT_CA_PATH := "http://certs.example.com/.well-known/est/cacerts"
DNS_CERT_SERVER_PATH := "http://certs.example.com/.well-known/eap/server"

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
	@echo "docker.powerdns - Build the 'dns' container image"

docker: docker.radius docker.powerdns

docker.deps:
	$(Q)docker build . -f docker/deps/Dockerfile -t $(DOCKER_IMAGE_DEPS):ubuntu20-deps

docker.radius: docker.deps
	$(Q)docker build . -f docker/server/radius/Dockerfile -t $(DOCKER_IMAGE_DEPS):service-radius

docker.powerdns: docker.deps
	$(Q)docker build . -f docker/server/powerdns/Dockerfile -t $(DOCKER_IMAGE_DEPS):service-dns

#
#  Run
#
docker.run: docker.radius.run docker.powerdns.run

docker.radius.run: docker.radius
	$(Q)docker run -dit --name service-radius \
		-e RADIUS_CLIENTS=$(RADIUS_CLIENTS) \
		-p 1812-1813:1812-1813/udp freeradius/automatic-eap:service-radius

docker.powerdns.run: docker.powerdns
	$(Q)docker run -dit --name service-dns \
		-e DNS_ZONE=$(DNS_ZONE) \
		-e DNS_RECORDS=$(DNS_RECORDS) \
		-e DNS_CERT_CA_PATH=$(DNS_CERT_CA_PATH) \
		-e DNS_CERT_SERVER_PATH=$(DNS_CERT_SERVER_PATH) \
		-p 53:53/udp freeradius/automatic-eap:service-dns

#
#  Clean
#
docker.clean: docker.radius.clean docker.powerdns.clean

docker.radius.clean:
	$(Q)docker rm -f service-radius

docker.powerdns.clean:
	$(Q)docker rm -f service-dns

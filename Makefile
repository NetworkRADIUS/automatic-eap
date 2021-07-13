#
#  Copyright 2021 NetworkRADIUS SARL (legal@networkradius.com)
#

DOCKER_IMAGE := freeradius
DOCKER_IMAGE_DEPS := $(DOCKER_IMAGE)/automatic-eap

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

docker.deps:
	$(Q)docker build . -f docker/deps/Dockerfile -t $(DOCKER_IMAGE_DEPS):ubuntu20-deps

docker.radius: docker.deps
	$(Q)docker build . -f docker/server/radius/Dockerfile -t $(DOCKER_IMAGE_DEPS):service-radius

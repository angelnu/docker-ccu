#!/bin/sh -e

#Load settings
test ! -e settings && cp -av settings.template settings
. ./settings

##########
# SCRIPT #
##########


docker build -t $DOCKER_ID .
docker tag $DOCKER_ID ${DOCKER_ID}:${CCU_VERSION}

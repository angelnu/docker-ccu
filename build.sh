#!/bin/sh -e

#Load settings
test ! -e settings && cp -av settings.template settings
. ./settings

##########
# SCRIPT #
##########


docker build -t $DOCKER_ID -t ${DOCKER_ID}:${CCU2_VERSION} .
if [[ ${DOCKER_ID} == */* ]]; then
  docker push $DOCKER_ID
  docker push ${DOCKER_ID}:${CCU2_VERSION}
fi

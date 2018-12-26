#!/bin/sh -e

#Load settings
test ! -e settings && cp -av settings.template settings
. ./settings

##########
# SCRIPT #
##########


docker build -t $DOCKER_ID .
if [[ ${DOCKER_ID} == */* ]]; then
  docker push $DOCKER_ID
fi

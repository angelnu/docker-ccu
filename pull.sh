#!/bin/sh -e

#Load settings
if [ -e settings ]; then
  . ./settings
else
  . ./settings.template
fi

##########
# SCRIPT #
##########

docker pull ${DOCKER_REPO}:${CCU_VERSION}
docker pull ${DOCKER_REPO}:${MAYOR_CCU_VERSION}
docker pull ${DOCKER_REPO}:latest

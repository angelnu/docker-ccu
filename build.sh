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

docker build -t ${DOCKER_REPO}:${CCU_VERSION} --build-arg CCU_VERSION=${CCU_VERSION} .
docker tag ${DOCKER_REPO}:${CCU_VERSION} ${DOCKER_REPO}:${MAYOR_CCU_VERSION}
docker tag ${DOCKER_REPO}:${CCU_VERSION} ${DOCKER_REPO}:latest

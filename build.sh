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


docker build -t ${DOCKER_ID}:${CCU_VERSION} --build-arg CCU_VERSION=${CCU_VERSION} .
docker tag ${DOCKER_ID}:${CCU_VERSION} ${DOCKER_ID}:${DOCKER_TAG}

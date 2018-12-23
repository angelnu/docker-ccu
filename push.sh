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


docker push ${DOCKER_REPO}:${CCU_VERSION}
docker push ${DOCKER_REPO}:${DOCKER_TAG}

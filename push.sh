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


docker push ${DOCKER_ID}:${CCU_VERSION}
docker push ${DOCKER_ID}:${DOCKER_TAG}

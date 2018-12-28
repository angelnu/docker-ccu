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

# Make sure only root can run our script
if [[ $EUID -ne 0 ]]; then
   echo "WARNING: This script should be run as root or with permissions for docker" 1>&2
fi

# For CCU2 the ccu2 branch must be used
if [ $MAYOR_CCU_VERSION -le 2 ]; then
  echo "ERROR: CCU_VERSION must be newer than 2 - please use the 'ccu2' git branch for the CCU2 firmware."
  exit 1
fi

docker build -t ${DOCKER_REPO}:${CCU_VERSION} --build-arg CCU_VERSION=${CCU_VERSION} .
docker tag ${DOCKER_REPO}:${CCU_VERSION} ${DOCKER_REPO}:${MAYOR_CCU_VERSION}
docker tag ${DOCKER_REPO}:${CCU_VERSION} ${DOCKER_REPO}:latest

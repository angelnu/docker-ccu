#!/bin/sh -e

#Load settings
test ! -e settings && cp -av settings.template settings
. ./settings

##########
# SCRIPT #
##########


<<<<<<< HEAD
docker build -t $DOCKER_ID .
if [[ ${DOCKER_ID} == */* ]]; then
  docker push $DOCKER_ID
fi
=======
docker build -t ${DOCKER_ID}:${CCU_VERSION} --build-arg CCU_VERSION=${CCU_VERSION} .
docker tag ${DOCKER_ID}:${CCU_VERSION} ${DOCKER_ID}:${DOCKER_TAG}
>>>>>>> parent of 264da13... Use settings tag

#!/bin/bash

# Stop on error
set -e

#Load settings
test ! -e settings && cp -av settings.template settings
. ./settings

####################
# Derived settings #
####################

CWD=$(pwd)
DOCKER_VOLUME_INTERNAL_PATH="/mnt"

##########
# SCRIPT #
##########

# Make sure only root can run our script
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

#Stop existing CCU2 docker
./undeploy.sh

#Calculate common options
DOCKER_START_OPTS="--name $DOCKER_NAME -p ${CCU2_REGA_PORT}:80 -p ${CCU2_RFD_PORT}:2001 -p ${CCU2_TCLREGASCRIPT_PORT}:8181 -e PERSISTENT_DIR=${DOCKER_VOLUME_INTERNAL_PATH} --hostname $DOCKER_NAME $DOCKER_OPTIONS $DOCKER_ID"

echo
if [ $DOCKER_MODE = swarm ] ; then
  echo "Starting as swarm service"

  #Install service that corrects permissions
  echo
  echo "Start ccu2 service"
  cp -a enableCCUDevices.sh /usr/local/sbin
  cp enableCCUDevices.service /etc/systemd/system/enableCCUDevices.service
  systemctl enable enableCCUDevices
  service enableCCUDevices restart

  DOCKER_START_OPTS="--detach=true --mount type=bind,src=/dev,dst=/dev_org --mount type=bind,src=/sys,dst=/sys_org --mount type=bind,src=${DOCKER_CCU2_DATA},dst=${DOCKER_VOLUME_INTERNAL_PATH} --network $DOCKER_NAME $DOCKER_START_OPTS"

  echo "docker service create $DOCKER_START_OPTS"
  docker service create $DOCKER_START_OPTS

elif [ $DOCKER_MODE = single ] ; then
  echo "Starting container as plain docker"

  DOCKER_START_OPTS="-d --restart=always -v /sys:/sys_org -v ${DOCKER_CCU2_DATA}:${DOCKER_VOLUME_INTERNAL_PATH} $DOCKER_START_OPTS"

  test -e /dev/ttyAMA0 && DOCKER_START_OPTS="--device=/dev/ttyAMA0:/dev_org/ttyAMA0:rwm $DOCKER_START_OPTS"
  test -e /dev/ttyS1   && DOCKER_START_OPTS="--device=/dev/ttyS1:/dev_org/ttyS1:rwm $DOCKER_START_OPTS"

  echo "docker run $DOCKER_START_OPTS"
  docker run $DOCKER_START_OPTS
else
  echo "No starting container: DOCKER_MODE = $DOCKER_MODE"
  exit 0
fi

echo
echo "Docker container started!"
echo "Docker data volume used: ${DOCKER_CCU2_DATA}"
if [[ ${DOCKER_CCU2_DATA} == */* ]]; then
  ln -sf ${DOCKER_CCU2_DATA}/etc/config/rfd.conf .
else
  echo "You can find its location with the command 'docker volume inspect ccu2_data'"
  docker volume inspect ${DOCKER_CCU2_DATA}
  ln -sf /var/lib/docker/volumes/${DOCKER_CCU2_DATA}/_data/etc/config/rfd.conf .
fi

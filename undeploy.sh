#!/bin/bash

# Stop on error
set -e

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

#Dissable enableCCUDevices service (swarm circumvention)
if [ -f /etc/systemd/system/enableCCUDevices.service ] ; then
  rm /etc/systemd/system/enableCCUDevices.service
  systemctl disable enableCCUDevices
  service enableCCUDevices stop
fi

#Remove container if already exits
echo
docker service ls 2>/dev/null|grep -q $DOCKER_NAME && echo "Stopping docker service $DOCKER_NAME"  && docker service rm $DOCKER_NAME
echo $(docker ps -a      |grep -q $DOCKER_NAME && echo "Stoping docker container $DOCKER_NAME" && docker stop $DOCKER_NAME && docker rm -f $DOCKER_NAME)

# Legacy
DOCKER_NAME="ccu2"
docker service ls 2>/dev/null|grep -q $DOCKER_NAME && echo "Stopping docker service $DOCKER_NAME"  && docker service rm $DOCKER_NAME
echo $(docker ps -a      |grep -q $DOCKER_NAME && echo "Stoping docker container $DOCKER_NAME" && docker stop $DOCKER_NAME && docker rm -f $DOCKER_NAME)

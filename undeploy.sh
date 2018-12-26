#!/bin/bash

# Stop on error
set -e

#Load settings
test ! -e settings && cp -av settings.template settings
. ./settings

##########
# SCRIPT #
##########

# Make sure only root can run our script
if [[ $EUID -ne 0 ]]; then
   echo "WARNING: This script should be run as root or with permissions for docker" 1>&2
fi

#Legacy: before we had a service
if [ -f /etc/systemd/system/ccu2.service ] ; then
  service ccu2 stop || true
  rm /etc/systemd/system/ccu2.service
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

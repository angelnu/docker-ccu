#!/bin/bash

# Stop on error
set -e

#Load settings
if [ -e settings ]; then
  . ./settings
else
  . ./settings.template
fi

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
   echo "WARNING: This script should be run as root or with permissions for docker" 1>&2
fi

# For CCU2 the ccu2 branch must be used
if [ $MAYOR_CCU_VERSION -le 2 ]; then
  echo "ERROR: CCU_VERSION must be newer than 2 - please use the 'ccu2' git branch for the CCU2 firmware."
  exit 1
fi

#Stop existing CCU docker
./undeploy.sh

#Udev rule for HmIP-RFUSB
if [ -d /etc/udev/rules.d ] && [ ! -e /etc/udev/rules.d/99-Homematic.rules ]; then
  cp -av host/99-Homematic.rules /etc/udev/rules.d/
  udevadm control --reload-rules
  udevadm trigger --action=add
fi

#This only works on Debian/Ubuntu based OSes such as Armbian and Raspbian
if which dpkg>/dev/null && ! modinfo eq3_char_loop >/dev/null 2>&1 ; then
  echo "Installing pivcpu extensions"

  #Add repository
  apt install -y wget
  wget -q -O - https://www.pivccu.de/piVCCU/public.key | apt-key add -
  bash -c 'echo "deb https://www.pivccu.de/piVCCU stable main" > /etc/apt/sources.list.d/pivccu.list'
  apt update

  #Install kernel headers
  if which armbian-config>/dev/null; then
    echo "Detected Armbian - install kernel sources and device tree"
    apt install -y `dpkg --get-selections | grep 'linux-image-' | grep '\sinstall' | sed -e 's/linux-image-\([a-z0-9-]\+\).*/linux-headers-\1/'`
    apt install -y pivccu-devicetree-armbian
  elif grep -q Raspbian /etc/os-release; then
    echo "Detected Raspbian - install kernel sources and raspberry modules"
    apt install -y pivccu-modules-raspberrypi
    echo
    echo "NOTE: please ensure that your GPIO UART is free if you plan to connect your CCU adapter to it"
    echo "See step 5 and 6 at https://github.com/alexreinert/piVCCU/blob/master/docs/setup/raspberrypi.md"
  else
    echo "Uknown platform - trying generic way to install kernel headers"
    apt install -y linux-headers-$(uname -r)
  fi

  #Install UART drivers
  apt install -y pivccu-modules-dkms

  echo
  echo "ATTENTION!!!!"
  echo "If you are connecting your Homematic adapter to a GPIO in Armbian you might need to reboot to get /dev/raw-uart"
  echo
fi

echo "Load eq3_char_loop module"
modprobe eq3_char_loop || true
echo eq3_char_loop>/etc/modules-load.d/eq3_char_loop.conf || true

echo "Enable realtime"
echo 'kernel.sched_rt_runtime_us=-1' > /etc/sysctl.d/10-ccu.conf || true
sysctl -w kernel.sched_rt_runtime_us=-1 || true

#Calculate common options
DOCKER_START_OPTS="--detach=true --name $DOCKER_NAME -p ${CCU_REGA_PORT}:80 -p ${CCU_RFD_PORT}:2001 -p ${CCU_IP_PORT}:2010 -p ${CCU_SSH_PORT}:22 -p ${CCU_TCLREGASCRIPT_PORT}:8181 -e PERSISTENT_DIR=${DOCKER_VOLUME_INTERNAL_PATH} --hostname $DOCKER_NAME $DOCKER_OPTIONS ${DOCKER_REPO}:${DOCKER_TAG}"
#Not needed with privileged - DOCKER_START_OPTS="--mount type=bind,src=/sys,dst=/sys --mount type=bind,src=/dev,dst=/dev ${DOCKER_START_OPTS}"
DOCKER_START_OPTS="--mount type=volume,src=${DOCKER_CCU_DATA},dst=${DOCKER_VOLUME_INTERNAL_PATH} ${DOCKER_START_OPTS}"
echo
if [ $DOCKER_MODE = swarm ] ; then
  echo "Starting as swarm service"

  #Install service that corrects permissions
  echo
  echo "Start ccu service"
  cp -a host/enableCCUDevices.sh /usr/local/sbin
  cp host/enableCCUDevices.service /etc/systemd/system/enableCCUDevices.service
  sed -i -e "s/DOCKER_NAME/$DOCKER_NAME/g"   /etc/systemd/system/enableCCUDevices.service
  systemctl daemon-reload
  systemctl enable enableCCUDevices
  service enableCCUDevices restart

  DOCKER_START_OPTS="--network $DOCKER_NAME $DOCKER_START_OPTS"

  echo "docker service create $DOCKER_START_OPTS"
  docker service create $DOCKER_START_OPTS

elif [ $DOCKER_MODE = single ] ; then
  echo "Starting container as plain docker"

  #Auto restart
  DOCKER_START_OPTS="--restart=always $DOCKER_START_OPTS"

  #Priviledged so it can access the dynamicaly created devices
  DOCKER_START_OPTS="--privileged $DOCKER_START_OPTS"
  #test -e /dev/raw-uart && DOCKER_START_OPTS="--device=/dev/raw-uart:/dev_org/ttyAMA0:rwm $DOCKER_START_OPTS"
  #test -e /dev/ttyAMA0  && DOCKER_START_OPTS="--device=/dev/ttyAMA0:/dev_org/ttyAMA0:rwm  $DOCKER_START_OPTS"
  #test -e /dev/ttyS1    && DOCKER_START_OPTS="--device=/dev/ttyS1:/dev_org/ttyS1:rwm      $DOCKER_START_OPTS"

  echo "docker run $DOCKER_START_OPTS"
  docker run $DOCKER_START_OPTS
else
  echo "No starting container: DOCKER_MODE = $DOCKER_MODE"
  exit 0
fi

echo
echo "Docker container started!"
echo "Docker data volume used: ${DOCKER_CCU_DATA}"
if [[ ${DOCKER_CCU_DATA} == */* ]]; then
  ln -sf ${DOCKER_CCU_DATA}/etc/config/rfd.conf .
else
  echo "You can find its location with the command 'docker volume inspect ccu_data'"
  docker volume inspect ${DOCKER_CCU_DATA}
  ln -sf /var/lib/docker/volumes/${DOCKER_CCU_DATA}/_data/etc/config/rfd.conf .
fi

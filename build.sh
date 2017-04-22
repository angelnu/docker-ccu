#!/bin/bash

# Stop on error
set -e


#CCU2 firmware version to download
: ${CCU2_VERSION:="2.21.10"}

#CCU2 Serial Number
: ${CCU2_SERIAL:="ccu2_docker"}

#Rega Port
value=${1:-the}
: ${CCU2_REGA_PORT:=80}

#Rfd Port
: ${CCU2_RFD_PORT:=2001}


#Docker version to download
#DOCKER_VERSION="1.10.3"

#Name of the docker volume where CCU2 data will persist
#It can be a local location as well such as a mounted NAS folder, cluster fs (glusterfs), etc.
: ${DOCKER_CCU2_DATA:="ccu2_data"}

#Docker ID is used to push built image to a docker repository (needed for docker swarm)
: ${DOCKER_ID:="ccu2"}

#Run with docker swarm?
: ${DOCKER_MODE:="single"}


##############################################
# No need to touch anything bellow this line #
##############################################

#URL used by CCU2 to download firmware
CCU2_FW_LINK="http://update.homematic.com/firmware/download?cmd=download&version=${CCU2_VERSION}&serial=${CCU2_SERIAL}&lang=de&product=HM-CCU2"

#URL used to download Docker for Raspi
#DOCKER_DEB_URL="https://downloads.hypriot.com/docker-hypriot_${DOCKER_VERSION}-1_armhf.deb"

CWD=$(pwd)
BUILD_FOLDER=${CWD}/build
CCU2_TGZ=ccu2-${CCU2_VERSION}.tgz
CCU2_UBI=rootfs-${CCU2_VERSION}.ubi
UBI_TGZ=ubi-${CCU2_VERSION}.tgz
DOCKER_BUILD=docker_build
DOCKER_VOLUME_INTERNAL_PATH="/mnt"
DOCKER_NAME=ccu2


echo "Checking device"
if grep -qi Raspberry /proc/device-tree/model; then
  echo "Detected Raspberry"
  SERIAL_DEVICE=/dev/ttyAMA0
elif grep -qi Orange /proc/device-tree/model; then
  echo "Detected Orange Pi"
  SERIAL_DEVICE=/dev/ttyS1
else
  echo "Do not recognize HW $(cat /proc/device-tree/model) -> Exiting"
  exit 1
fi



##########
# SCRIPT #
##########

mkdir -p ${BUILD_FOLDER}
cd ${BUILD_FOLDER}

echo
echo "Download CCU2 firmware"
#download
if [ -e $CCU2_TGZ ]; then
  echo "$CCU2_TGZ already exists - skip download"
else
  wget $CCU2_FW_LINK -O $CCU2_TGZ
fi

echo
echo "Extract UBI image from tarball"
if [ -e $CCU2_UBI ]; then
  echo "$CCU2_UBI already exists - skip"
else
  tar -xf $CCU2_TGZ rootfs.ubi
  mv rootfs.ubi $CCU2_UBI
fi

echo
echo "Extract UBI image content"
if [ -e $UBI_TGZ ]; then
  echo "$UBI_TGZ already exists - skip"
else
  if [ ! -d ubi_reader ]; then
    git clone https://github.com/jrspruitt/ubi_reader
  fi
  python -mplatform | grep -qi Ubuntu && apt-get update &&  apt-get install python-lzo || true
  python -mplatform | grep -qi ARCH && apt-get update &&  pip2 install python-lzo || true
  rm -rf ubi
  PYTHONPATH=ubi_reader python2 ubi_reader/scripts/ubireader_extract_files -k $CCU2_UBI -o ubi

  echo "Compress the result"
  tar -czf $UBI_TGZ -C ubi/*/root .
fi

#echo
#echo "Download Docker if needed"
#if docker -v|grep -q ${DOCKER_VERSION}; then
#  echo "skip"
#else
#  wget ${DOCKER_DEB_URL}
#  dpkg -i docker*.deb
#fi
echo
echo "Installing Docker if needed"
if docker -v|grep -qvi version; then
  apt-get install -y docker.io
fi

echo
echo "Build Docker container"
rm -rf $DOCKER_BUILD
mkdir $DOCKER_BUILD
cp -l ${CWD}/Dockerfile ${CWD}/entrypoint.sh $DOCKER_BUILD
cp -l $UBI_TGZ $DOCKER_BUILD/ubi.tgz
docker build -t $DOCKER_ID -t ${DOCKER_ID}:${CCU2_VERSION} $DOCKER_BUILD
docker push $DOCKER_ID
docker push ${DOCKER_ID}:${CCU2_VERSION}

echo
echo "Stopping  Docker container - $DOCKER_ID"
cd ${CWD}
#Remove container if already exits, then start it
docker service rm $DOCKER_NAME
docker ps -a |grep -v $DOCKER_ID && docker stop $DOCKER_NAME && docker rm $DOCKER_NAME

echo
echo "Start Docker container - $DOCKER_ID"
cd ${CWD}
if [ $DOCKER_MODE = swap ] ; then
  docker service create --name $DOCKER_NAME \
  -p ${CCU2_REGA_PORT}:80 \
  -p ${CCU2_RFD_PORT}:2001 \
  -e PERSISTENT_DIR=${DOCKER_VOLUME_INTERNAL_PATH} \
  --mount type=bind,src=/dev/ttyS1,dst=/dev/mmd_bidcos \
  --mount type=bind,src=/sys/devices,dst=/sys/devices \
  --mount type=bind,src=/sys/class/gpio,dst=/sys/class/gpio \
  --mount type=bind,src=${DOCKER_CCU2_DATA},dst=${DOCKER_VOLUME_INTERNAL_PATH} \
  $DOCKER_ID
else
  docker run --name $DOCKER_NAME \
  -d --restart=always \
  -p ${CCU2_REGA_PORT}:80 \
  -p ${CCU2_RFD_PORT}:2001 \
  --device=${SERIAL_DEVICE}:/dev/mmd_bidcos \
  -v /sys/devices:/sys/devices \
  -v /sys/class/gpio:/sys/class/gpio \
  -v ${DOCKER_CCU2_DATA}:${DOCKER_VOLUME_INTERNAL_PATH} \
  -e PERSISTENT_DIR=${DOCKER_VOLUME_INTERNAL_PATH} \
  $DOCKER_ID
fi

if [ -f /etc/systemd/system/ccu2.service ] ; then
  service ccu2 stop
  rm /etc/systemd/system/ccu2.service
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

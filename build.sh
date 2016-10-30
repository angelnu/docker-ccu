#!/bin/bash

#CCU2 firmware version to download
CCU2_VERSION="2.21.10"

#CCU2 Serial Number
CCU2_SERIAL="ccu2_docker"

#Docker version to download
DOCKER_VERSION="1.10.3"

#Name of the docker volume where CCU2 data will persist
DOCKER_CCU2_DATA="ccu2_data"



##############################################
# No need to touch anything bellow this line #
##############################################

#URL used by CCU2 to download firmware
CCU2_FW_LINK="http://update.homematic.com/firmware/download?cmd=download&version=${CCU2_VERSION}&serial=${CCU2_SERIAL}&lang=de&product=HM-CCU2"

#URL used to download Docker for Raspi
DOCKER_DEB_URL="https://downloads.hypriot.com/docker-hypriot_${DOCKER_VERSION}-1_armhf.deb"

CWD=$(pwd)
BUILD_FOLDER=${CWD}/build
CCU2_TGZ=ccu2-${CCU2_VERSION}.tgz
CCU2_UBI=rootfs-${CCU2_VERSION}.ubi
UBI_TGZ=ubi-${CCU2_VERSION}.tgz
DOCKER_BUILD=docker_build
DOCKER_ID="ccu2"




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
  apt-get install python-lzo
  rm -rf ubi
  PYTHONPATH=ubi_reader ubi_reader/scripts/ubireader_extract_files -k $CCU2_UBI -o ubi

  echo "Compress the result"
  tar -czf $UBI_TGZ -C ubi/*/root .
fi

echo
echo "Download Docker if needed"
if docker -v|grep -q ${DOCKER_VERSION}; then
  echo "skip"
else
  wget ${DOCKER_DEB_URL}
  dpkg -i docker*.deb
fi

echo
echo "Build Docker container"
rm -rf $DOCKER_BUILD
mkdir $DOCKER_BUILD
cp -l ${CWD}/Dockerfile ${CWD}/entrypoint.sh $DOCKER_BUILD
cp -l $UBI_TGZ $DOCKER_BUILD/ubi.tgz
docker build -t $DOCKER_ID -t ${DOCKER_ID}:${CCU2_VERSION} $DOCKER_BUILD

echo
echo "Start Docker container"
cd ${CWD}
#Remove container if already exits, then start it
docker ps -a |grep -v $DOCKER_ID && docker rm -f $DOCKER_ID
docker run --name $DOCKER_ID --net=host -tid -p 80:80 -p 2001:2001 --device=/dev/ttyAMA0 -v /sys/devices:/sys/devices -v /sys/class/gpio:/sys/class/gpio -v ${DOCKER_CCU2_DATA}:/usr/local ccu2

echo
echo "Start ccu2 service"
cp ccu2.service /etc/systemd/system/ccu2.service
systemctl enable ccu2
service ccu2 restart

echo
echo "Docker container started!"
echo "Docker data volume used: ${DOCKER_CCU2_DATA}"
echo "You can find its location with the command 'docker volume inspect ccu2_data'"
docker volume inspect ccu2_data

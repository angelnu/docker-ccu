#!/bin/bash

# Stop on error
set -e

#Load settings
test ! -e settings && cp -av settings.template settings
. ./settings

####################
# Derived settings #
####################

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

##########
# SCRIPT #
##########

# Make sure only root can run our script
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

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
  python -mplatform | grep -qi debian && apt-get update &&  apt-get install python-lzo || true
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
cp -l ubi_reader/LICENSE $DOCKER_BUILD/LICENSE
docker build -t $DOCKER_ID -t ${DOCKER_ID}:${CCU2_VERSION} $DOCKER_BUILD
if [[ ${DOCKER_ID} == */* ]]; then
  docker push $DOCKER_ID
  docker push ${DOCKER_ID}:${CCU2_VERSION}
fi


#!/bin/bash

enableAccess(){
  CIDS=`docker ps --no-trunc -q --filter name=ccu2|head -1`
  if [[ -z $CIDS ]]; then
      echo 'CID not found'
      return
  fi
  for CID in $CIDS; do
    echo "Setting permissions for image $CID"
    echo "c *:* rwm" > /sys/fs/cgroup/devices/docker/$CID/devices.allow
  done
}

enableAccess
while true; do
docker events --filter 'event=start'| \
while read line; do
    enableAccess
done
sleep 1
done

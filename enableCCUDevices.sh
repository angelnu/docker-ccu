#!/bin/bash
enableAccess(){
CID=`docker ps --no-trunc -q --filter ancestor=angelnu/ccu2|head -1`
if [[ -z $CID ]]; then
    echo 'CID not found'
    exit
fi
echo "Setting permissions for image $CID"
echo "c *:* rwm" > /sys/fs/cgroup/devices/docker/$CID/devices.allow
}

enableAccess
while true; do
docker events --filter 'event=start'| \
while read line; do
    enableAccess
done
sleep 1
done

# docker-ccu
Homematic CCU firmware running as docker container on arm and (emulated) x86.

This build downloads the CCU2 firmware for the Homematic, re-package it as docker image and (optionally) push it to docker hub. You can then start it on your raspi. Other ARM-based boards might also work (see Dependencies section). You can deploy on x86 but it will be slow and some components fail. I am working a true multi-arch docker container for this.

If you want to skip the build and just download the ready to use docker container please visit:
 - [old CCU2](https://hub.docker.com/r/angelnu/ccu2/)
 - [CCU3 and newer](https://hub.docker.com/r/angelnu/ccu/)

## How to deploy

 1. ssh into your ARM device
 2. `sudo -i`
 3. git clone this repository
 4. (Optional) `cp -a settings.template settings` and edit it
 5. `./deploy.sh`

## Dependencies

* ARM HW. Following combinations tested:
  * raspberry (tested on raspberry 3) and raspberrian jessy
  * Orange Pi Plus 2 and Armbian (Ubuntu 16.04 and Kernel 4.9) - Self built
  * OdroidXU4 (with a LAN GW)

## What is left
- support for Homematic IP with a single device
  - special kernel modules are needed to duplicate which cannot be loaded into a docker container
  - using the [HmIP-RFUSB](https://www.elv.de/elv-homematic-ip-rf-usb-stick-hmip-rfusb-fuer-alternative-steuerungsplattformen-arr-bausatz.html) should work but not tested yet.
  - looking at [USB adapter](https://homematic-forum.de/forum/viewtopic.php?f=69&t=47691)
- create true multiarch dynamic docker
  - current multiarch is based on qemu
  - will use OCCU as base as done by this other [project](https://github.com/litti/dccu2)
- automatically build new docker containers when new CCU versions are published by e3q.

## How to build
This is only needed if you do not use the already built docker container. If this is the case you can skip this and just deploy. You can build on arm or x86 computers.

1. ssh into your ARM device
2. `sudo -i`
3. git clone this repository
4. (Optional) `cp -a settings.template settings` and edit it
5. `./build.sh`

After the above steps you can connect to <IP address of your raspberry>. The CCU docker image will be started automatically on every boot of the raspberry: the container is started in auto-restart mode.

## How to update to a new CCU firmware
Just update the CCU_VERSION field in _settings_ and execute:

1. (optional) `./build.sh`
2. `/deploy.sh`

Your CCU settings will be preserved.

## How to configure local antenna
If you have added a [homematic radio module](http://www.elv.de/homematic-funkmodul-fuer-raspberry-pi-bausatz.html) to your raspberry, then you can use it with your CCU2 docker image. If not, you would need to use the external LAN gateway. You can also use a combination of both.

### Instructions
1. (raspberry 3) You need to avoid that the bluetooth module uses the HW UART. You can either disable it or let it use the miniUART. I use the second option but since I do not use Bluetooth on the Raspi I do not know if this breaks it. More info [here](http://raspberrypi.stackexchange.com/questions/45570/how-do-i-make-serial-work-on-the-raspberry-pi3).
   * Add `dtoverlay=pi3-miniuart-bt`to _/boot/config.txt_
2. (raspberry) Make sure that the serial console is not using the UART
   * Replace `console=ttyAMA0,115200` with `console=tty1` in _/boot/cmdline.txt_
   * More info [here](http://raspberrypihobbyist.blogspot.de/2012/08/raspberry-pi-serial-port.html)
4. Run again `./deploy.sh`

## How to import settings from an existing CCU

### Using the CCU UI (recommend)
1. log into you HW CCU web ui
2. go to Settings -> CCU maintenance -> create backup
3. go into the the docker CCU web UI
4. go to Settings -> CCU maintenance -> restore backup

### Manually copying files
Please notice that this method does not support switch HW versions: to update from HW CCU2 to docker CCU you need to use the UI

1. Enable ssh in your CCU2. Instructions (in German) [here](https://www.homematic-inside.de/tecbase/homematic/generell/item/zugriff-auf-das-dateisystem-der-ccu-2)
2. ssh into your rapberry
3. `sudo -i`
4. `./undeploy.sh`
5. Copy the old rfd.conf: `cp /var/lib/docker/volumes/ccu2_data/_data/etc/config/rfd.conf{,org}`
6. `rsync -av \[your CCU2 IP\]/usr/local/*  /var/lib/docker/volumes/ccu2_data/_data/`
7. Diff the orginal rfd.conf with the one you copied from the CCU2: `diff -u /var/lib/docker/volumes/ccu2_data/_data/etc/config/rfd.conf{,org}`
8. Make sure you keep the original lines for:
   * `#Improved Coprocessor Initialization = true` - commented out
   * ` AccessFile = /dev/null` - notice the blank at the start of the line
   * ` ResetFile = /dev/ccu2-ic200` - notice the blank at the start of the line
9. `./deploy.sh`

## Deploying in a docker cluster
### Kubernetes
You can check this [example](https://github.com/angelnu/homecloud/blob/master/services/ccu2.yaml) of a high available deployment. There I keep the configuration into a cluster persistent volume (glusterfs) so if one of computers is down then the CCU is "just" redeployed automatically into another available computer.

### Docker swarm
You can also deploy this docker image to a docker swarm. For this you need to:
* set up a docker swarm in multiple Raspberries. They all need to have local antennas at least you use a LAN gateway
* have a shared folder mounted at the same location in all the members of the cluster. Examples:
  * Mount a NAS folder. This is simple but then the NAS is the single point of failure
  * Cluster FS such as glusterfs. TBD: upload instructions

1. Change _settings_ parameters
   * Set _DOCKER_CCU_DATA_ to the absolute path of your shared folder. Example: `_/media/glusterfs/ccu_`
   * Set _DOCKER_MODE_ to `swarm`
   * Set _DOCKER_OPTIONS_ to `--constraint node.labels.architecture==arm`
2. `./deploy.sh`

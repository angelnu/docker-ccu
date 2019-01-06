# docker-ccu
Homematic CCU firmware running as docker container on arm and (emulated) x86.

This project downloads the Homematic CCU2 firmware and re-package it as docker image. You can then start it on your raspi. Other ARM-based boards might also work (see Dependencies section). You can deploy on x86 but it will be slow and some components fail. I am working on a true multi-arch docker container for this.

An automated build pushes new docker images to [Docker Hub](https://hub.docker.com/r/angelnu/ccu/). You can check there the available versions.

Support for CCU2 has been removed from the HEAD. Please checkout the [ccu2 branch](https://github.com/angelnu/docker-ccu2/tree/ccu2) if you need to build the CCU2 images. There is also another Docker Hub repository with [old CCU2](https://hub.docker.com/r/angelnu/ccu2/) images.

## Features
- deploy original CCU firmware to Docker and kubernetes
  - addons, ssh and any other feature from the original CCU not listed under [Not Working section](#not-working)
- Homematic and Homematic IP supported (wired not tested)
- automatically install support for Homematic HW - thanks to [Alex´s piVCCU proyect](https://github.com/alexreinert/piVCCU)
- partial multiarch:
  - builds on x86
  - runs on x86 but HMServer does not start
- displays Duty Cycle for CCU Gateways - thanks to [Andreas and Jens](https://github.com/jens-maus/RaspberryMatic/issues/219)
- keep configuration in a remote location specified with the env variable PERSISTENT_DIR - you can use any location supported by rsync

## Not working
- Settings -> Control Panel -> Network Settings
- Display when there is a new CCU version available
- true multiarch dynamic docker
  - current multiarch is based on qemu
  - will use OCCU as base as done by this other [project](https://github.com/litti/dccu2)
  - looking at [USB adapter](https://homematic-forum.de/forum/viewtopic.php?f=69&t=47691) for dual stack with a single device
- automatically build new docker containers when new CCU versions are published by e3q.

## Dependencies

- [Docker](https://docs.docker.com/install/linux/docker-ce/ubuntu/)
  - Kubernetes and Docker Swarm can be used for High Availability set ups. See the [cluster section](#cluster) for more details.
- ARM HW. Following combinations tested for both Homematic and Homematic IP:
  - Raspberry with HM-MOD-RPI-PCB
  - Orange Pi Plus 2 with HM-MOD-RPI-PCB
  - OdroidXU4 with HM-LGW-O-TW-W-EU and HmIP-RFUSB
- One or more adapters to connect to the Homematic and/or Homematic IP devices
  - Homematic LAN GW for Homematic devices:
    - [HM-LGW-O-TW-W-EU](https://www.elv.de/homematic-funk-lan-gateway.html)
    - [RaspberryMatic in LAN GW mode](https://github.com/jens-maus/RaspberryMatic#cake-exclusive-features-not-available-in-ccu2ccu3-firmware)
    - Docker computer and LAN GW need to be in the same network. No additional SW is needed in the docker computer. Connection is configured using the CCU web UI (settings -> LAN Gateway configuration)
  - Homematic USB IP adapter
    - [HmIP-RFUSB](https://www.elv.de/elv-homematic-ip-rf-usb-stick-hmip-rfusb-fuer-alternative-steuerungsplattformen-arr-bausatz.html)
    - the required kernel module is `cp210x` which is available in most Linux systems. The `deploy.sh` will add a udev rule to enable it automatically when plugged.
  - HM-MOD-RPI-PCB, RPI-RF-MOD, HB-RF-USB and emulated adapters
    - additional packages need to be installed in the host to support Homematic and Homematic IP in parallel. The required packages come from the [piVCCU project](https://github.com/alexreinert/piVCCU) which supports multiple [ARM devices](https://github.com/alexreinert/piVCCU#prequisites)
    - the `deploy.sh` script will try to install the _pivccu_ packages for you. If it does not work please follow [these instructions](https://github.com/alexreinert/piVCCU#manual-installation) to install `pivccu-modules-dkms`, `pivccu-devicetree-armbian` (if you are on Armbian) and `pivccu-modules-raspberrypi` (if you use a Raspberry with Raspbian). You do not need to install a network bridge since docker manages that.


## How to deploy

   1. ssh into the target computer (better an ARM device)
   2. git clone this repository
   3. (Optional) `cp -a settings.template settings` and edit `settings.template`
   4. `sudo ./deploy.sh`
      - you can also use env variables such as `MAYOR_CCU_VERSION=2` to deploy a CCU2 firmware. See [settings.template](settings.template) for all available options

  After the above steps you can connect to the <IP address of your computer >:<port 80>. The CCU docker image will be restarted automatically when the computer boots: the container is started in auto-restart mode. With `docker ps ccu` you can see its status.




## How to build
This is only needed if you do not use the already built docker container.

1. git clone this repository
2. (Optional) `cp -a settings.template settings` and edit `settings.template`
3. `sudo ./build.sh`

## How to update to a new CCU firmware

1. `./pull.sh `
2. `./deploy.sh`

Optionally you can use the _CCU_VERSION_ variable to select a particular version.

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

You can move your settings from an existing CCU into the docker CCU, either via ssh or using the native backup/restore support in the CCU (recommended).

If you use a HM-MOD-RPI-PCB and the Homematic is not working after restoring the backup then likely your old system was running without compatibility with Homematic IP. You need to use the new dual-stack mode. The easiest way to achieve that is to execute the following command: `docker exec ccu sh -c "rm /etc/config/rfd.conf && /etc/init.d/S61rfd restart && cat /etc/config/rfd.conf"`. After this please check that `Improved Coprocessor Initialization = true`.

### Using the CCU UI (recommend)
1. log into you HW CCU web ui
2. go to Settings -> Security -> create backup
3. go into the the docker CCU web UI
4. go to Settings -> Security -> import backup

### Manually copying files
Please notice that this method does not support switch HW versions: to update from HW CCU2 to docker CCU you need to use the UI

1. Enable ssh in your CCU2. Instructions (in German) [here](https://www.homematic-inside.de/tecbase/homematic/generell/item/zugriff-auf-das-dateisystem-der-ccu-2)
2. ssh into your target computer
3. `sudo ./undeploy.sh`
4. `rsync -av \[your CCU IP\]/usr/local/*  /var/lib/docker/volumes/ccu_data/_data/`
5. `./deploy.sh`

## Cluster

You can deploy this docker container into a docker cluster with Kubernetes or Docker Swarm. This allows a High Available configuration where the home automation can stay up in the event of HW dying. This is usefull considering that a Raspberry is cheap so you should not depend on a single one to ensure your house stays warm ;-) .

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

# docker-ccu2
Script to create a docker container with the CCU2 firmware on the raspberry

This script will download the CCU2 firmware for the Homematic, re-package it as docker image and start it on your raspi.

##Dependencies

* raspberry (tested on raspberry 3)
* raspberrian jessy
* no programs using ports 80 and 2001

##How to install
1. git clone this repository in your raspberrian
2. (Optional) Edit the default settings in _build.sh_
2. execute _build.sh_
3. (optional) Delete the cloned repo: the docker image and its data are stored in _/var/docker_

After the above steps you can connect to <IP address of your raspberry>. The CCU2 docker image will be started automatically on every boot of the raspberry. For this a service called `ccu2` is added (only works with systemd)

##How to configure local antena
If you have added a [homematic radio module](http://www.elv.de/homematic-funkmodul-fuer-raspberry-pi-bausatz.html) to your raspberry, then you can use it with your CCU2 docker image.

###Intructions
1. (raspberry 3) You need to avoid that the bluetoth module uses the HW UART. You can either disable it or let it use the miniUART. I use the second option but since I do not use Bluetoth on the Raspi I do not know if this breaks it. More info [here](http://raspberrypi.stackexchange.com/questions/45570/how-do-i-make-serial-work-on-the-raspberry-pi3).
  * Add `dtoverlay=pi3-miniuart-bt`to _/boot/config.txt_
2. Make sure that the serial console is not using the UART
  * Replace `console=ttyAMA0,115200` with `console=tty1` in _/boot/cmdline.txt_
  * More info [here](http://raspberrypihobbyist.blogspot.de/2012/08/raspberry-pi-serial-port.html)
3. Edit _rfd.conf_. This is at _/var/lib/docker/volumes/ccu2_data/_data/etc/config/rfd.conf_. You also have a symlink in _<git checkout>/rfd.conf_
4. Add the following lines at the end of the file
   ```
[Interface 0]
Type = CCU2
Description = CCU2-Coprocessor
ComPortFile = /dev/ttyAMA0
AccessFile = /dev/null
ResetFile = /sys/class/gpio/gpio18/value
   ```
  * NOTE: If you had added other Interfaces make sure that you update their index. If you have `Interface 0` twice then none will be used.
5. _service ccu2 restart_


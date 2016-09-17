#!/bin/sh
# export GPIO
if [ ! -d /sys/class/gpio/gpio18 ] ; then
  echo 18 > /sys/class/gpio/export
fi
echo out > /sys/class/gpio/gpio18/direction
/etc/init.d/S50lighttpd start
/bin/eq3configcmd update-coprocessor -lgw -u -rfdconf /etc/config/rfd.conf -l 1
/bin/eq3configcmd update-lgw-firmware -m /firmware/fwmap -c /etc/config/rfd.conf -l 1
/bin/eq3configcmd update-lgw-firmware -m /firmware/fwmap -c /etc/config/hs485d.conf -l 1
/bin/rfd -f /etc/config/rfd.conf -l 1 &
/etc/init.d/S62HMServer start
/etc/init.d/S70ReGaHss start
/bin/sh

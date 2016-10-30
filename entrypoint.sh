#!/bin/sh
echo "Configuring GPIO"
if [ ! -d /sys/class/gpio/gpio18 ] ; then
  echo 18 > /sys/class/gpio/export
fi
echo out > /sys/class/gpio/gpio18/direction

echo "Starting CCU2 init scripts"
for i in /etc/init.d/S*; do echo; echo "Starting $i"; $i start; done

echo "Done starting CCU2 init scripts"
/bin/sh

#/etc/init.d/S50lighttpd start
#/bin/eq3configcmd update-coprocessor -lgw -u -rfdconf /etc/config/rfd.conf -l 1
#/bin/eq3configcmd update-lgw-firmware -m /firmware/fwmap -c /etc/config/rfd.conf -l 1
##/bin/eq3configcmd update-lgw-firmware -m /firmware/fwmap -c /etc/config/hs485d.conf -l 1
#/bin/rfd -f /etc/config/rfd.conf -l 1 &
#/etc/init.d/S62HMServer start
#/etc/init.d/S70ReGaHss start
#/bin/sh

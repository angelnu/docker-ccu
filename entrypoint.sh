#!/bin/sh
LOCAL_PERSISTENT_DIR=/usr/local/
echo "Checking device"
if grep -qi Raspberry /sys_org/firmware/devicetree/base/model; then
  echo "Detected Raspberry"
  SERIAL_DEVICE=/dev_org/ttyAMA0
  GPIO_PORT=18
elif grep -qi Orange /sys_org/firmware/devicetree/base/model; then
  echo "Detected Orange Pi"
  SERIAL_DEVICE=/dev_org/ttyS3
  GPIO_PORT=110
else
  echo "Did not recognize HW $(cat /sys_org/firmware/devicetree/base/model) -> Homematic PCB adapter will not work"
  #Enable some cicumventions for missing antenna
fi

if [ -n $PERSISTENT_DIR ] ; then
  echo "Copying from $PERSISTENT_DIR to $LOCAL_PERSISTENT_DIR"
  if [ -n $CHECK_PERSISTENT_DIR ] ; then
    echo "Check that $PERSISTENT_DIR is not empty"
    if [ "$(ls -A $PERSISTENT_DIR)" ]; then
      echo "Ok - not empty -> Continue with copy"
    else
      echo "Error - empty -> wait for 15 seconds and then terminate container"
      sleep 15
      exit 1
    fi
  fi
  rsync -av $PERSISTENT_DIR/* $LOCAL_PERSISTENT_DIR/
fi

if [ ! -z $SERIAL_DEVICE ] ; then
  ln -s ${SERIAL_DEVICE} /dev/mmd_bidcos
fi

if [ ! -z $GPIO_PORT ] ; then
  echo "Configuring GPIO in port ${GPIO_PORT}"
  if [ ! -d /sys_org/class/gpio/gpio${GPIO_PORT} ] ; then
    echo ${GPIO_PORT} > /sys_org/class/gpio/export
  fi
  echo out > /sys_org/class/gpio/gpio${GPIO_PORT}/direction
  ln -sf /sys_org/class/gpio/gpio${GPIO_PORT}/value /dev/ccu2-ic200
fi

echo
echo "Check if /etc/config/keys exits"
if [ ! -f /etc/config/keys ] ; then
cat <<EOF > /etc/config/keys
current Index = 1
Key 0 =
Key 1 = $(cat /dev/urandom|tr -dc A-F0-9 | head -c32)
Last Index = 0
EOF
echo "Created /etc/config/keys with urandom"
cat /etc/config/keys
fi

echo
echo "Check if /etc/config/ids exits"
if [ ! -f /etc/config/ids ] ; then
cat <<EOF > /etc/config/ids
BidCoS-Address=0x12EC17
SerialNumber=GEQ0174613
EOF
echo "Created /etc/config/ids with hard-coded serial numbers"
cat /etc/config/ids
fi

echo
echo "Starting CCU2 init scripts"
for i in /etc/init.d/S*; do echo; echo "Starting $i"; $i start; done
killall hss_led #Because it is very verbose when it cannot find the CCU2 leds
echo "Done starting CCU2 init scripts"

echo
echo "Register trap for SIGTERM"
finish () {
  echo "Terminating"
  if [ ! -z $PERSISTENT_DIR ] ; then
    echo "Copying from $LOCAL_PERSISTENT_DIR to $PERSISTENT_DIR"
    rsync -av --delete $LOCAL_PERSISTENT_DIR/* $PERSISTENT_DIR/
  fi
  exit 0
}
trap finish SIGTERM

while true; do
  #Regulary copy back to the persistent storage
  if [ ! -z $PERSISTENT_DIR ] ; then
    rsync -av --delete $LOCAL_PERSISTENT_DIR/* $PERSISTENT_DIR/
  fi
  sleep 600
done



#OLD: before we used to start selected services only
#/etc/init.d/S50lighttpd start
#/bin/eq3configcmd update-coprocessor -lgw -u -rfdconf /etc/config/rfd.conf -l 1
#/bin/eq3configcmd update-lgw-firmware -m /firmware/fwmap -c /etc/config/rfd.conf -l 1
##/bin/eq3configcmd update-lgw-firmware -m /firmware/fwmap -c /etc/config/hs485d.conf -l 1
#/bin/rfd -f /etc/config/rfd.conf -l 1 &
#/etc/init.d/S62HMServer start
#/etc/init.d/S70ReGaHss start
#/bin/sh

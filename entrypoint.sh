#!/bin/sh
LOCAL_PERSISTENT_DIR=/usr/local/

if [ -n "$PERSISTENT_DIR" ] ; then
  echo "Copying from $PERSISTENT_DIR to $LOCAL_PERSISTENT_DIR"
  if [ -n "$CHECK_PERSISTENT_DIR" ] ; then
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

echo
echo "Starting CCU services"
for i in /etc/init.d/S*; do echo; echo "Starting $i"; $i start; done
echo "Done starting CCU services"

echo
echo "Register trap for SIGTERM"
finish () {
  echo "Stopping CCU services"
  for i in /etc/init.d/S*; do echo; echo "Stopping $i"; $i stop; done
  if [ ! -z $PERSISTENT_DIR ] ; then
    echo "Copying from $LOCAL_PERSISTENT_DIR to $PERSISTENT_DIR"
    rsync -av --delete $LOCAL_PERSISTENT_DIR/* $PERSISTENT_DIR/
  fi
  echo "Terminating"
  exit 0
}
trap finish SIGTERM

while true; do
  #Regulary copy back to the persistent storage
  if [ ! -z $PERSISTENT_DIR ] ; then
    rsync -av --delete $LOCAL_PERSISTENT_DIR/* $PERSISTENT_DIR/
  fi
  # Sleep while reacting to signals
  sleep 600 &
  wait $!
done

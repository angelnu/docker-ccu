# /dev/raw_uart
UART used to connect to the HM adapter, typically plugged in the GPIO.

The UART must support the extensions from eq3 in order to run with Homematic and Homematic IP in parallel. This requires patched UART kernel modules. The piVCCU project has a DKMS package with patched UART kernel modules for multiple ARM boards. Without the modified patch the board can only be used in legacy mode for Homematic. This requires patching the rfd.conf file.

The piVCCU project also has an emulated UART to fake a PCB adapter and simulate both Homematic and Homematic IP.

# /dev/eq3loop

Provided by the kernel module `eq3_char_loop`. This device is needed by the `multimacd` eQ3 daemon in oder to multiplex Homematic and Homematic IP over the same coprocessor.

If this device is not present then the multimacd is not started (see patch)

# /dev/mmd_bidcos

This device is created by `multimacd` and consumed by the rfd daemon in order to control Homematic devices. Using this device requires `Improved Coprocessor Initialization = true` in _rfd.conf_ to work. In this mode no ResetFile is needed.

The rfd can run connected directly to the uart device. This is the legacy exlusive mode before adding the Homematic IP stack. When running in legacy mode the rfd.conf should look like this (notice the bank in front of the AccessFile and ResetFile in order to prevent them to be commented out at boot time):

```
#Improved Coprocessor Initialization = true

[Interface 0]
Type = CCU2
ComPortFile = /dev/mmd_bidcos
 AccessFile = /dev/null
 ResetFile = /dev/ccu2-ic200
```

# /dev/mmd_hmip

This device is created by `multimacd` and by the hmipserver to manage Homematic IP devices.

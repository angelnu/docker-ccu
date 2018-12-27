# Starting CCU services
1. Starting /etc/init.d/S00InstallAddon
   - trigger: /usr/local/.doAddonInstall
   - extract /usr/local/tmp/new_addon.tar.gz
   - execute /usr/local/tmp/update_script in chroot
   - only /usr/local is persistent   
2. Starting /etc/init.d/S00watchdog
   - skipping - not needed in container
3. Starting /etc/init.d/S01InitHost
   - Detect HW and set HM_HOST, HM_HOST_GPIO_UART, HM_HOST_GPIO_RESET and LEDs
   - values can be overwritten by docker env values
   example output:
    - Did not recognize HW Hardware	: ODROID-XU4 -> Homematic PCB adapter will not work
    - /dev/raw-uart does not exists: disabling UART
4. Starting /etc/init.d/S02InitRTC
   - skipping - Real Time Controler not needed for docker
   - RTC (if any) should be used by host - container gets time from host
5. Starting /etc/init.d/S03InitURandom
   - skipping - random seed done by host
6. Starting /etc/init.d/S04CheckFactoryReset
   - Checking for Factory Reset: not required
7. Starting /etc/init.d/S04CheckResizeLocalFS
   - S04CheckResizeLocal - skipping
8. Starting /etc/init.d/S05CheckBackupRestore
   Checking for Backup Restore: not required
9. Starting /etc/init.d/S06InitSystem
   - mkdir: can't create directory '/var/lib/dbus': No such file or directory
   - chmod: /var/lib/dbus: No such file or directory
   - Initializing System: OK
10. Starting /etc/init.d/S07logging
    - Starting logging: OK
11. Starting /etc/init.d/S10udev
    - S10udev - skipping
12. Starting /etc/init.d/S11InitRFHardware
    - Identifying Homematic RF-Hardware: HmIP-RFUSB (1b1f:c020) USB stick is connected -> ensure you do the following on the host:
      - modprobe cp210x
     - echo 1b1f c020 >/sys/bus/usb-serial/drivers/cp210x/new_id
    - BidCos-RF: none, HmIP: HMIP-RFUSB, OK
14. Starting /etc/init.d/S12UpdateRFHardware
    - ls: /firmware/HmIP-RFUSB/hmip_coprocessor_update-\*.eq3: No such file or directory
    - Updating Homematic RF-Hardware: HMIP-RFUSB: 2.8.6=>;, OK
15. Starting /etc/init.d/S13irqbalance
    - S13irqbalance - skipping
16. Starting /etc/init.d/S21rngd
    - S21rngd - skipping
17. Starting /etc/init.d/S30dbus
    - Starting system message bus: done
18. Starting /etc/init.d/S31bluetooth
    - S31bluetooth - skipping
19. Starting /etc/init.d/S40network
    - S40network - skipping
20. Starting /etc/init.d/S45ifplugd
    - S45ifplugd - skipping
21. Starting /etc/init.d/S48MigrateSecuritySettings
    - Starting : OK
22. Starting /etc/init.d/S48ntp
    - Starting ntpd: OK
23. Starting /etc/init.d/S49hs485d
    - Preparing start of hs485d: OK
24. Starting /etc/init.d/S49xinetd
    - Starting xinetd: OK
25. Starting /etc/init.d/S50eq3configd
    - Starting eq3configd: OK
26. Starting /etc/init.d/S50lighttpd
    - Starting lighttpd: OK
27. Starting /etc/init.d/S50ssdpd
    - Starting ssdpd: OK
28. Starting /etc/init.d/S50sshd
29. Starting /etc/init.d/S55InitAddons
    - Initializing Third-Party Addons: OK
30. Starting /etc/init.d/S58LGWFirmwareUpdate
    - Starting LGWFirmwareUpdate: .cryptEnabled true.cryptEnabled true.OK
31. Starting /etc/init.d/S59SetLGWKey
    - Setting LAN Gateway keys: OK
32. Starting /etc/init.d/S59snmpd
    - Starting SNMP daemon: FAIL
33. Starting /etc/init.d/S60hs485d
    - Starting hs485d: OK
34. Starting /etc/init.d/S60multimacd
    - Starting multimacd: Skipping
35. Starting /etc/init.d/S60openvpn
36. Starting /etc/init.d/S61rfd
    - Starting rfd:
    - sh: 286: unknown operand
    - sh: 286: unknown operand
    - Waiting for rfd to get ready.........rfd is ready now.
37. Starting /etc/init.d/S62HMServer
    - Starting HMIPServer: (/dev/ttyUSB0) .........OK
38. Starting /etc/init.d/S70ReGaHss
    - Starting ReGaHss: .OK
39. Starting /etc/init.d/S71crond
    - Starting crond: OK
40. Starting /etc/init.d/S97CloudMatic
    - Starting CloudMatic: OK
41. Starting /etc/init.d/S97NeoServer
    - Version is up to date / or Bigger
42. Starting /etc/init.d/S98StartAddons
    - Starting Third-Party Addons: OK
43. Starting /etc/init.d/S99SetupLEDs
    - Setup onboard LEDs: booted, OK

# Done starting CCU services

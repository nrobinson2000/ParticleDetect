#!/bin/bash

# Basic setup script for devices
# Works on OSX + should also work for Unix.
# Users of Windows 10 (or higher) can likely use the builtin Ubuntu install.
#
# We need to do the following:
# 1. Query the computer for the relevant USB port
# 2. Set the device to listening mode (if required)
# 3. Query the device for the deviceID
# 4. Set the Wifi Credentials using credentials stored in text file:
#    "particle serial wifi /dev/tty.usbmodem1451 --file defaultwifi.json"
# 5. Claim the device (make sure you're logged in with the correct user!)
# 6. Set the device DFU mode, so we can upload firmware
# 7. Flash our device test & setup firmware via Serial:
#    particle serial flash setup.bin
#
# Thanks to:
# @rickkas7 for examples in https://github.com/rickkas7/particle-device-helper
# @jrodas for examples https://community.particle.io/t/firmware-tips-and-tricks/3649/35
# Written by https://community.particle.io/u/jenschr
#
# Use as you like on your own responsibility :-)

# 1. cross platform (unix+OSX) way to grab the USB port name for the Particle device

a="ls /dev/tty.usbmodem*"
b="$(echo $a)"


# remove the returned part "ls " (3 chars) using cut
c="$(echo $b | cut -c3-)"

# 2. Set listen mode (yep - 3 times in a row for those annoying boards that do not respond at once)
d="$(stty -f $c 28800)"
echo $d
sleep 1

# The above will normally set the device to Listen mode, but since it may fail in some cases we'll confirm here
read -p "Is the device in Listen Mode (blue blink) (y/n)?" choice
case "$choice" in
  y|Y ) echo "yes";;
  n|N ) exit;;
  * ) exit;;
esac

# 3. Figure out the DeviceID (Requires Particle CLI installed)
f="$(particle identify)"
#echo $f

# extract the 25 char deviceID from what "particle identify" returned
g=${f:19:25}
if [ ${#g} -lt 15 ]; then
	# if the deviceID is less than 15 chars, it didn't work so just exit
	echo "Can't find a valid deviceID. Make sure the device is in Listen Mode (Blue blink)"
	exit
else
	echo "A device with ID $g was detected"
fi

# 4. setup the wifi credentials
h=""
i="$(particle serial wifi -q $c --file defaultwifi.json)"

#5 Wait 10 seconds and then claim the device
echo "Wifi setup finished, now wait a little for the device to connect so we can claim it"
sleep 10
d="$(particle cloud claim $g)"
echo $d

# 6. Set device to DFU mode
echo "Getting ready to flash firmware"
sleep 2
j="$(stty -f $c 14400)"
echo $j

# 7. Flash our test software
sleep 2
k="$(particle flash --usb setup.bin)"

echo "done! $k"

# since your setup file will usually need to display some output, we'll open the serial monitor so you can check it all worked
sleep 2
exec particle serial monitor --follow

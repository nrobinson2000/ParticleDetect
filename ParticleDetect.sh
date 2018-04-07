#!/bin/bash

# Basic setup script for particle devices
# Works on OSX and should also work for Linux.
# Users of Windows 10 (or higher) can likely use the builtin Ubuntu install.
#
# This script does the following:
# 1. Query the computer for the relevant USB port
# 2. Set the device to listening mode (if required)
# 3. Query the device for the deviceID
# 4. Set the Wifi Credentials using credentials stored in text file:
#    "particle serial wifi --port /dev/tty.usbmodem1451 --file defaultwifi.json"
# 5. Claim the device (make sure you're logged in with the correct user!)
# 6. Set the device DFU mode, so we can upload firmware
# 7. Flash our device test & setup firmware via Serial:
#    particle serial flash setup.bin
#
# USAGE:
# ./ParticleDetect.sh            # You will have to will confirm device is in listening mode. Serial monitor will not open.
# ./ParticleDetect.sh -y         # You will not have to confirm device is in listening mode. Serial monitor will not open.
# ./ParticleDetect.sh monitor    # You will have to will confirm device is in listening mode. Serial monitor will open.
# ./ParticleDetect.sh -y monitor # You will not have to confirm device is in listening mode. Serial monitor will open.
#
# PREREQUISITES:
#  - particle-cli must be installed
#  - defaultwifi.json must be present
#  - setup.bin must be present
#  - On Linux: custom-baud must be present or recompiled (if you want)
#
# Thanks to:
# @rickkas7 for examples in https://github.com/rickkas7/particle-device-helper
# @jrodas for examples https://community.particle.io/t/firmware-tips-and-tricks/3649/35
# @nrobinson2000 for improvements to this script
# Written by https://community.particle.io/u/jenschr
#
# Use as you like on your own responsibility :-)

# Caveat: Linux cannot use stty to set the baud rate to 28800 and 14400
# like OSX can. custom-baud is a C executable for Linux that can get around this.

# Add custom-baud to PATH
PATH="$PATH:$PWD/custom-baud"

# 1. cross platform (Linux/OSX) way to grab the USB port name for the Particle device

if [[ "$(uname -s)" == "Linux" ]]; then
  for modem in /dev/ttyACM*
  do
    MODEM="$modem"
  done
elif [[ "$(uname -s)" == "Darwin" ]]; then
  for modem in /dev/cu.usbmodem*
  do
    MODEM="$modem"
  done
fi

# 2. Set listening mode (yep - 3 times in a row for those annoying boards that do not respond at once)

if [[ "$(uname -s)" == "Linux" ]]; then
  custom-baud "$MODEM" 28800 # Linux can't use stty for 28800
elif [[ "$(uname -s)" == "Darwin" ]]; then
  stty -f "$MODEM" 28800
fi

sleep 1

# The above will normally set the device to Listen mode, but since it may fail in some cases we'll confirm here
# Override with ./ParticleDetect.sh -y

if [[ "$1" != "-y" ]] && [[ "$2" != "-y" ]]; then
read -p "Is the device in Listen Mode (blue blink) (y/n)?: " choice
case "$choice" in
  y|Y ) echo "yes";;
  n|N ) exit;;
  * ) exit;;
esac
fi

# 3. Figure out the DeviceID (Requires Particle CLI installed)
f="$(particle identify)"
# extract the 25 char deviceID from what "particle identify" returned
g=${f:19:24}

if [ ${#g} -lt 15 ]; then
	# if the deviceID is less than 15 chars, it didn't work so just exit
	echo "Can't find a valid deviceID. Make sure the device is in Listen Mode (Blue blink)."
	exit
else
	echo "A device with ID $g was detected."
fi

# 4. setup the wifi credentials
particle serial wifi -q --port "$MODEM" --file defaultwifi.json

# defaultwifi.json - "particle help serial wifi" for more info

# {
#   "network": "my_ssid",
#   "security": "WPA2_AES",
#   "password": "my_password"
# }

#5 Wait 10 seconds and then claim the device
echo "Wifi setup finished.
Waiting a little for the device to connect so we can claim it."
sleep 10

d="$(particle cloud claim $g)"
echo $d

# 6. Set device to DFU mode
echo "Getting ready to flash firmware."
sleep 2

if [[ "$(uname -s)" == "Linux" ]]; then
  custom-baud "$MODEM" 14400 # Linux can't use stty for 14400
elif [[ "$(uname -s)" == "Darwin" ]]; then
  stty -f "$MODEM" 14400
fi

# 7. Flash our test software
sleep 2

# You need to have setup.bin in this same directory
particle flash --usb setup.bin

echo "Done!"

# enable with "./ParticleDetect.sh -y monitor" or "./ParticleDetect.sh monitor"
if [[ "$1" == "monitor" ]] || [[ "$2" == "monitor" ]]; then
  # since your setup file will usually need to display some output, we'll open the serial monitor so you can check it all worked
  sleep 2
  exec particle serial monitor --follow # On Linux this will probably put the device back into DFU mode unintentionally
fi

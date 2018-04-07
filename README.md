# Basic setup script for particle devices
Works on OSX and should also work for Linux.
Users of Windows 10 (or higher) can likely use the builtin Ubuntu install.

# This script does the following:
1. Query the computer for the relevant USB port
2. Set the device to listening mode (if required)
3. Query the device for the deviceID
4. Set the Wifi Credentials using credentials stored in text file:

```
particle serial wifi --port /dev/tty.usbmodem1451 --file defaultwifi.json
```

5. Claim the device (make sure you're logged in with the correct user!)
6. Set the device DFU mode, so we can upload firmware
7. Flash our device test & setup firmware via USB:

```
particle flash --usb setup.bin
```

# USAGE:

```
./ParticleDetect.sh            # You will have to will confirm device is in listening mode. Serial monitor will not open.
./ParticleDetect.sh -y         # You will not have to confirm device is in listening mode. Serial monitor will not open.
./ParticleDetect.sh monitor    # You will have to will confirm device is in listening mode. Serial monitor will open.
./ParticleDetect.sh -y monitor # You will not have to confirm device is in listening mode. Serial monitor will open.
```

# PREREQUISITES:
- `particle-cli` must be installed
- `defaultwifi.json` must be present
- `setup.bin` must be present
- On Linux: `custom-baud` must be present or recompiled (if you want)

# Thanks to:
@rickkas7 for examples in https://github.com/rickkas7/particle-device-helper

@jrodas for examples https://community.particle.io/t/firmware-tips-and-tricks/3649/35

@nrobinson2000 for improvements to this script https://github.com/nrobinson2000/ParticleDetect

Written by https://community.particle.io/u/jenschr

#### Use as you like on your own responsibility :-)

**Caveat:** Linux cannot use stty to set the baud rate to 28800 and 14400 like OSX can. custom-baud is a C executable for Linux that can get around this.

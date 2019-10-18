# qtCrossCompileRpi3Buster

This script creates a QT Creator cross-compile environment for a Rasberry Pi 3 (Buster Lite) on an Ubuntu 18.04.3LTS PC.

Prior to running this script, on the Raspberry Pi you should do the following:

We need to install some development libraries, so the first thing to do is to allow the system to install source packages, for this you only have to uncomment the deb-src line in the /etc/apt/sources.list file, which configures the system repositories.

    sudo nano /etc/apt/sources.list

The next step is to update and install the required development packages.

    sudo apt update
    sudo apt upgrade
    sudo reboot
    sudo apt-get build-dep qt4-x11
    sudo apt-get build-dep libqt5gui5
    sudo apt-get install libudev-dev libinput-dev libts-dev libxcb-xinerama0-dev libxcb-xinerama0
    sudo apt-get install gdbserver

Finally, prepare target folder

    sudo mkdir /usr/local/qt5pi
    sudo chown pi:pi /usr/local/qt5pi

# Run the script

Simply:

    chmod +x qtCrossCompileRpi3Buster.sh
    ./qtCrossCompileRpi3Buster.sh

# On Completion use the following settings in QT Creator

C++ Compiler: /opt/qt5pi/tools/arm-bcm2708/gcc-linaro-arm-linux-gnueabihf-raspbian/bin/arm-linux-gnueabihf-g++

C Compiler: /opt/qt5pi/tools/arm-bcm2708/gcc-linaro-arm-linux-gnueabihf-raspbian/bin/arm-linux-gnueabihf-gcc

Debugger: /opt/qt5pi/tools/arm-bcm2708/gcc-linaro-arm-linux-gnueabihf-raspbian/bin/arm-linux-gnueabihf-gdb

QT Version: /opt/qt5pi/qt5/bin/qmake

# References & Thanks to

[mechatronicsblog](https://mechatronicsblog.com/cross-compile-and-deploy-qt-5-12-for-raspberry-pi/)

[qt wiki](https://wiki.qt.io/RaspberryPi2EGLFS)



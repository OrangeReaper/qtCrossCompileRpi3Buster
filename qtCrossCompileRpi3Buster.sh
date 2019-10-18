#!/bin/bash

#Script variables
QTV="5.10"
PIV="pi"

read -p "Shutdown when finished? " -n 1 -r
echo    # move to a new line
SHUTDOWN=$REPLY

read -p "Install Dependancies? " -n 1 -r
echo    # move to a new line
DEPENDANCIES=$REPLY

if [ ! -d /opt/qt5pi/sysroot ]; then
  SYSROOT='y'
else
  read -p "Recreate sysroot? " -n 1 -r
  echo    # move to a new line
  SYSROOT=$REPLY
fi

# Install dependancies
if [[ $DEPENDANCIES =~ ^[Yy]$ ]]
then
  echo
  date +"%H:%M:%S"
  echo Installing Dependancies
  echo =======================
  sudo apt-get -y update
  sudo apt-get -y upgrade
  sudo apt-get -y install git bison python gperf
  sudo apt-get -y install lib32z1
fi

#create folders if required
if [ ! -d /opt/qt5pi ]; then
  echo
  date +"%H:%M:%S"
  echo Creating Folders
  echo ================ 
  sudo mkdir /opt/qt5pi
  sudo chown andy:andy /opt/qt5pi
fi
cd /opt/qt5pi

#Create toolchain if required
if [ ! -d /opt/qt5pi/tools ]; then
  echo
  date +"%H:%M:%S"
  echo Creating Toolchain
  echo =================
  # download toolchain
  git clone https://github.com/raspberrypi/tools
fi

#We are creating here a sysroot for Raspberry Pi cross compilation in our computer.
if [[ $SYSROOT =~ ^[Yy]$ ]]
then
  rm -Rf /opt/qt5pi/sysroot
  mkdir sysroot sysroot/usr sysroot/opt

  #We can use rsync to synchronize our computer sysroot and the Raspberry Pi.
  echo
  date +"%H:%M:%S"
  echo Synchronising sysroot with RPi
  echo ==============================
  echo 'starting /lib (1 of 4)'
  rsync -az pi@andymote.local:/lib sysroot
  echo 'starting /usr/include (2 of 4)'
  rsync -az pi@andymote.local:/usr/include sysroot/usr
  echo 'starting /usr/lib (3 of 4)'
  rsync -az pi@andymote.local:/usr/lib sysroot/usr
  echo 'starting /opt/vc (4 of 4)'
  rsync -az pi@andymote.local:/opt/vc sysroot/opt
  #Next, we need to adjust our symbolic links in sysroot to be relative since this folder structure is in both our computer and Raspberry Pi.
  echo
  date +"%H:%M:%S"
  echo Adjusting Symbolic Links
  echo ========================
  if [ ! -f /opt/qt5pi/sysroot-relativelinks.py ]; then
    wget https://raw.githubusercontent.com/riscv/riscv-poky/master/scripts/sysroot-relativelinks.py
    chmod +x sysroot-relativelinks.py
  fi
  ./sysroot-relativelinks.py sysroot
fi

echo
date +"%H:%M:%S"
echo 'Creating clean QT Folder (qtbase)'
echo =================================
if [ ! -d /opt/qt5pi/qtbase ]; then
  git clone git://code.qt.io/qt/qtbase.git -b $QTV
else
  cd /opt/qt5pi/qtbase/
  git clean -dfx
fi

#In new Raspbian versions [BUSTER is assumed here], EGL libraries have different names than those assumed in Qt configuration files.
# Edit the qmake.conf file  to fix this; substitute all references to -lEGL and -LGLESv2 for -lbrcmEGL and -lbrcmGLESv2, respectively.
sed -i 's/-lEGL/-lbrcmEGL/g' /opt/qt5pi/qtbase/mkspecs/devices/linux-rasp-$PIV-g++/qmake.conf
sed -i 's/-lGLESv2/-lbrcmGLESv2/g' /opt/qt5pi/qtbase/mkspecs/devices/linux-rasp-$PIV-g++/qmake.conf

#Configure Qt for cross compilation
echo
date +"%H:%M:%S"
echo 'Configuring QT for Cross Compilation'
echo ====================================1
rm -Rf /opt/qt5pi/qt5
rm -Rf /opt/qt5pi/qt5pi
cd /opt/qt5pi/qtbase/
./configure -release -opengl es2 -device linux-rasp-$PIV-g++ -device-option CROSS_COMPILE=/opt/qt5pi/tools/arm-bcm2708/gcc-linaro-arm-linux-gnueabihf-raspbian/bin/arm-linux-gnueabihf- -sysroot /opt/qt5pi/sysroot -opensource -confirm-license -make libs -prefix /usr/local/qt5pi -extprefix /opt/qt5pi/qt5pi -hostprefix /opt/qt5pi/qt5 -no-use-gold-linker -v -no-gbm

echo
date +"%H:%M:%S"
echo 'Running make'
echo  ============
make -j7 > ~/raspi/make.log

echo
date +"%H:%M:%S"
echo 'Running make install'
echo  ====================
make install > ~/raspi/install.log

#Once Qt is compiled, it can be deployed to your Raspberry Pi using the rsync command
cd /opt/qt5pi
echo
date +"%H:%M:%S"
echo 'Synchronising result with Rpi'
echo  =============================
rsync -az qt5pi pi@andymote.local:/usr/local

echo
echo 'Setup for QT Creator'
echo '===================='
echo 'C++ Compiler: /opt/qt5pi/tools/arm-bcm2708/gcc-linaro-arm-linux-gnueabihf-raspbian/bin/arm-linux-gnueabihf-g++'
echo 'C Compiler: /opt/qt5pi/tools/arm-bcm2708/gcc-linaro-arm-linux-gnueabihf-raspbian/bin/arm-linux-gnueabihf-gcc'
echo 'Debugger: /opt/qt5pi/tools/arm-bcm2708/gcc-linaro-arm-linux-gnueabihf-raspbian/bin/arm-linux-gnueabihf-gdb'
echo 'QT Version: /opt/qt5pi/qt5/bin/qmake'

echo
date +"%H:%M:%S"
echo 'Finished'
echo  ========

if [[ $SHUTDOWN =~ ^[Yy]$ ]]; then
  /home/andy/Scripts/autoshutdown.sh &
fi
 
exit 0    

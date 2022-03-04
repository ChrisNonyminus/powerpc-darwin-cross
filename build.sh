#!/bin/bash

set -e

#note: needed packages to be installed for this to compile: build-essential, git, wine
#additional needed packages to be installed to compile the test: ssh

#run this script from the root of the repo

#set important variables
export SCRIPT_DIR=$(pwd) 
export WHO_AM_I=$(whoami)

#ensure we're in ~
cd ~

#options
export OLD_BISON_PATH=/tmp/bison
export YOUR_CPU_COUNT=9 #change to a number that's ideally in between half of your cpu count and your total cpu count
export COMPILER_INSTALL_PATH=/opt/powerpc-darwin-cross
export APPLE_GCC_VERSION=5370
export WINEPATH="Z:$OLD_BISON_PATH/bin"
export OLD_BISON="wine Z:$OLD_BISON_PATH/bin/bison"

#extract gcc
mkdir -p ~/tmp/xnu-gcc
wget -c https://opensource.apple.com/tarballs/gcc/gcc-${APPLE_GCC_VERSION}.tar.gz -O - | tar -xz -C ~/tmp/xnu-gcc/

#extract old-ass version of bison
mkdir -p ${OLD_BISON_PATH}

unzip -o ${SCRIPT_DIR}/bison-2.4.1-bin.zip -d ${OLD_BISON_PATH}
unzip -o ${SCRIPT_DIR}/bison-2.4.1-dep.zip -d ${OLD_BISON_PATH}
alias bison=${OLD_BISON} #temporarily reroute bison to OLD_BISON

#clone cctools-port
rm -rf ~/tmp/cctools-port
git clone https://github.com/tpoechtrager/cctools-port.git ~/tmp/cctools-port

#make the install directory and give the user permissions to use it
echo -e "Creating the prefix directory. We have to use sudo to do so..."
sudo mkdir -p ${COMPILER_INSTALL_PATH}
sudo chown ${WHO_AM_I} ${COMPILER_INSTALL_PATH}

#compile cctools-port
cd ~/tmp/cctools-port
cd cctools
./configure --target=powerpc-apple-darwin --prefix=${COMPILER_INSTALL_PATH}
make -j${YOUR_CPU_COUNT}
make install

set +e #gcc compilation will fail at one point but at that point the compilers we need will already be compiled so it doesn't matter
#compile gcc
cd ~/tmp/xnu-gcc/gcc-${APPLE_GCC_VERSION}
git apply ${SCRIPT_DIR}/gcc.patch
rm -rf build
mkdir -p build
cd build
LANGUAGES=c,c++ CFLAGS="-fno-stack-protector -U_FORTIFY_SOURCE -D_FORTIFY_SOURCE=0" ../configure --target=powerpc-apple-darwin --prefix=${COMPILER_INSTALL_PATH}
make -j${YOUR_CPU_COUNT}

set -e
#set up executables
cd ${COMPILER_INSTALL_PATH}
cd bin
for f in powerpc-apple-darwin-*
do
	if [[ -f "$f" ]]; then
		mv "$f" "${f/powerpc\-apple\-darwin-/}"
	fi
done
if [[ -f ld ]]; then
	rm ${COMPILER_INSTALL_PATH}/bin/ld #we are not using cctools-port's ld
fi
cd ~/tmp/xnu-gcc/gcc-${APPLE_GCC_VERSION}/build/gcc
cp xgcc ${COMPILER_INSTALL_PATH}/bin/xgcc
cp gcc-cross ${COMPILER_INSTALL_PATH}/bin/gcc-cross
cp g++ ${COMPILER_INSTALL_PATH}/bin/g++
cp g++-cross ${COMPILER_INSTALL_PATH}/bin/g++-cross
cp cpp ${COMPILER_INSTALL_PATH}/bin/cpp
cp cc1 ${COMPILER_INSTALL_PATH}/bin/cc1
cp cc1plus ${COMPILER_INSTALL_PATH}/bin/cc1plus

#done...?
echo -e "\n\nHopefully, everything worked correctly and\ngcc was compiled and installed successfully (Ignore the error it spits out above, that's just gcc's tests throwing a fit about paths. The compiler is what we need, and hopefully it was copied over by this script).\nHowever, there are still some more steps\nyou need to take."
echo -e "\n\nOn your actual PowerPC Mac, you must have XCode installed\n(preferrably whatever version of XCode\nthe version of gcc you compiled came with)."
echo -e "\nThen, using ftp or ssh, copy the files from\nyour Mac's /usr/include folder to $COMPILER_INSTALL_PATH/powerpc-apple-darwin/include."
echo -e "\n\nOnce that's done, you are technically\ndone setting up the cross-compiler on\nyour Linux machine.\n\nHOWEVER..."
echo -e "\n\nAlthough you can cross-compile to mac\njust fine, the linker from\ncctools-port does not work for powerpc targets."
echo -e "\n\nSo, to compile stuff for Mac, you must\nhave a step in your makefile\nto copy stuff over to your mac\nvia ssh and then run your mac's internal ld\ncommand via ssh."
echo -e "\nSee tests/helloworld/Makefile to see what I mean."
echo -e "\nIt's ugly, I know, but it's the only way."
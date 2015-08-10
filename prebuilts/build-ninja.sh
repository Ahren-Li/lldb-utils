#!/bin/bash -ex
# latest version of this file can be found at
# https://android.googlesource.com/platform/external/lldb-utils
#
# Download & build ninja on the local machine
# works on Linux, OSX, and Windows (Git Bash)
# leaves output in /tmp/prebuilts/ninja/$OS-x86/

PROJ=ninja
VER=1.5.3
MSVS=2013

source $(dirname "$0")/build-common.sh build-common.sh

# needed for cygwin
export PATH="$PATH":.

# ninja specific steps
cd $RD
git clone https://github.com/martine/ninja.git src
cd src
git checkout v$VER
if [[ "$OS" == "windows" ]] ; then
	PLATFORM="--platform=msvc"
fi
./configure.py --bootstrap $PLATFORM

# install
cp $RD/src/ninja $INSTALL

commit_and_push


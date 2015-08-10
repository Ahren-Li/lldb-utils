#!/bin/bash -ex
# latest version of this file can be found at
# https://android.googlesource.com/platform/external/lldb-utils
#
# Download & build swig on the local machine
# works on Linux, OSX, and Windows (Cygwin w/make 4.1, curl, gcc 4.9.2)
# leaves output in /tmp/prebuilts/swig/$OS-x86
# cmake must be installed on Windows

PROJ=swig
VER=2.0.11

source $(dirname "$0")/build-common.sh build-common.sh

TGZ=$PROJ-$VER.tar.gz
curl -L http://downloads.sourceforge.net/project/swig/swig/$PROJ-$VER/$TGZ -o $TGZ
tar xzf $TGZ || cat $TGZ
mkdir -p $RD/build
cd $RD/build

# build PCRE as a static library from a tarball just for use during the SWIG build.
# GNU make 3.81 (MinGW version) crashes on Windows
curl -L ftp://ftp.csx.cam.ac.uk/pub/software/programming/pcre/pcre-8.37.tar.gz -o pcre-8.37.tar.gz
$RD/$PROJ-$VER/Tools/pcre-build.sh

$RD/$PROJ-$VER/configure --prefix=$INSTALL
make -j$CORES
make install
cd $INSTALL/bin
ln -s swig swig2.0

commit_and_push

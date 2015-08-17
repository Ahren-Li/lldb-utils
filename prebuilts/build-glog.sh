#!/bin/bash -ex
# latest version of this file can be found at
# https://android.googlesource.com/platform/external/lldb-utils
#
# Download & build glog on the local machine
# works on Linux, OS X
# TODO: get it working on Windows
# leaves output in /tmp/prebuilts/libglog/$OS-x86

PROJ=libglog
VER=0.3.4

source $(dirname "$0")/build-common.sh build-common.sh

BASE=${PROJ#lib}-$VER
TGZ=v${VER}.tar.gz

curl -L https://github.com/google/glog/archive/$TGZ -o $TGZ

tar xzf $TGZ || cat $TGZ # if this fails, we're probably getting an http error
cd $BASE
mkdir $RD/build
cd $RD/build
$RD/$BASE/configure --prefix=$INSTALL
make -j$CORES
make install

commit_and_push

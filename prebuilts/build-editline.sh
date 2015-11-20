#!/bin/bash -ex
# latest version of this file can be found at
# https://android.googlesource.com/platform/external/lldb-utils
#
# Download & build libedit on the local machine
# works on Linux, OSX, and Windows (Cygwin)
# leaves output in /tmp/prebuilts/libedit/$OX-x86
# cmake must be installed on Windows

PROJ=libedit
VER=20150325-3.1

source "$(dirname "${BASH_SOURCE[0]}")/build-common.sh" "$@"

BASE=$PROJ-$VER
TGZ=$BASE.tar.gz

curl -L http://thrysoee.dk/editline/$TGZ -o $TGZ

tar xzf $TGZ || cat $TGZ # if this fails, we're probably getting an http error
cd $BASE
mkdir $RD/build
cd $RD/build
$RD/$BASE/configure --prefix=$INSTALL
make -j$CORES
make install

finalize_build

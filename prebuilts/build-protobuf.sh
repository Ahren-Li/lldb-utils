#!/bin/bash -ex
# latest version of this file can be found at
# https://android.googlesource.com/platform/external/lldb-utils
#
# Download & build protobuf on the local machine
# works on Linux, OS X
# TODO: get it working on Windows
# leaves output in /tmp/prebuilts/libprotobuf/$OS-x86
# requires autoconf, automake, libtool, chrpath

PROJ=libprotobuf
VER=2.5.0

source $(dirname "$0")/build-common.sh build-common.sh

BASE=${PROJ#lib}-$VER
TGZ=v${VER}.tar.gz

curl -L https://github.com/google/protobuf/archive/$TGZ -o $TGZ

tar xzf $TGZ || cat $TGZ # if this fails, we're probably getting an http error
cd $BASE
./autogen.sh
mkdir $RD/build
cd $RD/build
$RD/$BASE/configure --prefix=$INSTALL
make -j$CORES
make install

case "$OS" in
	linux)
		for TARGET in $INSTALL/{bin/protoc,lib/libprotoc.so.8}; do
			chrpath -r '$ORIGIN/../lib' $TARGET
		done
		;;
	darwin)
		for LIB in lib/libproto{c,buf{,-lite}}.8.dylib; do
			install_name_tool -id @executable_path/../$LIB $INSTALL/$LIB
			for TARGET in $INSTALL/{bin/protoc,lib/libprotoc.8.dylib}; do
				ABSOLUTE=$INSTALL/$LIB
				RELATIVE=@executable_path/../$LIB
				install_name_tool -change $ABSOLUTE $RELATIVE $TARGET
			done
		done
		;;
esac

commit_and_push

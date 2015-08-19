#!/bin/bash -ex
# latest version of this file can be found at
# https://android.googlesource.com/platform/external/lldb-utils
#
# Download & build protobuf on the local machine
# works on Linux, OS X, and Windows (Cygwin)
# leaves output in /tmp/prebuilts/libprotobuf/$OS-x86
# requires autoconf, automake, libtool, chrpath

PROJ=libprotobuf
VER=2.6.1
MSVS=2013

source $(dirname "$0")/build-common.sh build-common.sh

BASE=${PROJ#lib}-$VER
TGZ=v${VER}.tar.gz

curl -L https://github.com/google/protobuf/archive/$TGZ -o $TGZ

tar xzf $TGZ || cat $TGZ # if this fails, we're probably getting an http error
cd $BASE
./autogen.sh

case "$OS" in
	windows)
		cd vsprojects
		sed -i 's/\(IntermediateDirectory=\)".*"/\1"$(OutDir)$(ProjectName)"/' *.vcproj
		devenv protobuf.sln /Upgrade
		devenv protobuf.sln /Build Debug
		devenv protobuf.sln /Build Release
		mkdir -p $INSTALL/Debug $INSTALL/Release
		cp -a Debug/*.* $INSTALL/Debug
		cp -a Release/*.* $INSTALL/Release
		cmd /c extract_includes.bat
		cp -a include $INSTALL/
		;;
	linux|darwin)
		mkdir $RD/build
		cd $RD/build
		$RD/$BASE/configure --prefix=$INSTALL
		make -j$CORES
		make install
		;;
esac

case "$OS" in
	linux)
		for TARGET in $INSTALL/{bin/protoc,lib/libprotoc.so}; do
			chrpath -r '$ORIGIN/../lib' $TARGET
		done
		;;
	darwin)
		for LIB in lib/libproto{c,buf{,-lite}}.9.dylib; do
			install_name_tool -id @executable_path/../$LIB $INSTALL/$LIB
			for TARGET in $INSTALL/{bin/protoc,lib/libprotoc.dylib}; do
				ABSOLUTE=$INSTALL/$LIB
				RELATIVE=@executable_path/../$LIB
				install_name_tool -change $ABSOLUTE $RELATIVE $TARGET
			done
		done
		;;
esac

commit_and_push

#!/bin/bash
# Expected arguments:
# $1 = out_dir
# $2 = dest_dir
# $3 = build_number

if [ "$(uname)" != Linux ]; then
	# This may not be true, but I haven't tested it yet.
	echo "This script will only work on linux." >&2
	exit 1
fi

if [ ! "$BUILD" ]; then
	OS=linux
	LLDB_UTILS=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)
        source "$LLDB_UTILS/build-common.sh" "$@"
fi

export ANDROID_NDK_HOME=/raid0ssd/lili/20.1.5948944/
export ANDROID_PLATFORM=android-28

for ARCH in x86 x86_64 armeabi arm64-v8a; do

BUILD=$OUT/lldb/$ARCH
rm -rf "$BUILD"
mkdir -p "$BUILD"

unset CMAKE_OPTIONS
CMAKE_OPTIONS+=(-GNinja)
CMAKE_OPTIONS+=(-H"$LLVM")
CMAKE_OPTIONS+=(-B"$BUILD")
CMAKE_OPTIONS+=(-C"$LLDB_UTILS/config/android-$ARCH.cmake")
CMAKE_OPTIONS+=(-DCMAKE_MAKE_PROGRAM="$NINJA")
CMAKE_OPTIONS+=(-DPYTHON_EXECUTABLE="$PYTHON_DIR/bin/python")
CMAKE_OPTIONS+=(-DLLVM_EXTERNAL_LLDB_SOURCE_DIR="$LLDB")
CMAKE_OPTIONS+=(-DLLVM_EXTERNAL_CLANG_SOURCE_DIR="$CLANG")
CMAKE_OPTIONS+=(-DCROSS_TOOLCHAIN_FLAGS_NATIVE="-C$LLDB_UTILS/config/linux.cmake")

"$CMAKE" "${CMAKE_OPTIONS[@]}"
"$CMAKE" --build "$BUILD" --target lldb-server
DESTDIR=$BUILD/stage "$CMAKE" -DCMAKE_INSTALL_COMPONENT=lldb-server -DCMAKE_INSTALL_DO_STRIP=ON \
	-P "$BUILD/cmake_install.cmake"

mkdir -p "$INSTALL/android/$ARCH"
cp -aL "$BUILD/stage/bin/lldb-server" "$INSTALL/android/$ARCH/"

done # for ARCH

pushd "$INSTALL/android"
zip --filesync --recurse-paths --symlinks "$DEST/lldb-android-${BNUM}.zip" .
popd

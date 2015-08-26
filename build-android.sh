#!/bin/bash
# Expected arguments:
# $1 = out_dir
# $2 = dest_dir
# $3 = build_number

# exit on error
set -e

if [ ! "${BASH_SOURCE[1]}" ]; then
	case "$(uname -s)" in
		Linux)
			ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
			source "$ROOT_DIR/external/lldb-utils/build.sh" "$@"
			exit 0
			;;
		*)
			echo "No." > /dev/stderr
			exit 1
	esac
fi

HOST="$BUILD"

CONFIG=MinSizeRel

for ARCH in x86 x86_64 arm aarch64 mips mips64; do

BUILD="$OUT/lldb/$ARCH"
rm -rf "$BUILD"
mkdir -p "$BUILD"

unset LLDB_FLAGS
unset LLDB_LINKER_FLAGS
unset LLDB_LIBS
unset CMAKE_OPTIONS

ABI=$ARCH
TRIPLE_ARCH=$ARCH
SYSROOT_ARCH=$ARCH
STL_ARCH=$ARCH

case $ARCH in
    x86)
        TOOLCHAIN="$PREBUILTS/gcc/linux-x86/x86/x86_64-linux-android-4.9"
        LLVM_ARCH=X86 TRIPLE_ARCH=i386 ABI=x86_64
        LLDB_FLAGS+=(-m32)
        ;;
    x86_64)
        TOOLCHAIN="$PREBUILTS/gcc/linux-x86/x86/x86_64-linux-android-4.9"
        LLVM_ARCH=X86
        ;;
    arm)
        TOOLCHAIN="$PREBUILTS/gcc/linux-x86/arm/arm-linux-androideabi-4.9"
        LLVM_ARCH=ARM STL_ARCH=armeabi-v7a ABI=armeabi
        ;;
    aarch64)
        TOOLCHAIN="$PREBUILTS/gcc/linux-x86/aarch64/aarch64-linux-android-4.9"
        LLVM_ARCH=AArch64 SYSROOT_ARCH=arm64 STL_ARCH=arm64-v8a
        ;;
    mips)
        TOOLCHAIN="$PREBUILTS/gcc/linux-x86/mips/mips64el-linux-android-4.9"
        LLVM_ARCH=Mips ABI=mips64
        LLDB_FLAGS+=(-mips32)
        ;;
    mips64)
        TOOLCHAIN="$PREBUILTS/gcc/linux-x86/mips/mips64el-linux-android-4.9"
        LLVM_ARCH=Mips
        ;;
esac

SYSROOT="$PREBUILTS/ndk/current/platforms/android-21/arch-$SYSROOT_ARCH"

# Necessary because mips64el-gcc searches paths relative to lib64.
[ $ARCH == mips ] && mkdir -p "$SYSROOT/usr/lib64"

STL="$PREBUILTS/ndk/current/sources/cxx-stl/gnu-libstdc++/4.9"

LLDB_FLAGS+=(-s) # stripped
LLDB_FLAGS+=(-I"$STL/include")
LLDB_FLAGS+=(-I"$STL/libs/$STL_ARCH/include")

LLDB_LINKER_FLAGS+=(-L"$STL/libs/$STL_ARCH")

LLDB_LIBS="gnustl_static"

# http://b.android.com/182094
[ $ARCH == mips ] && LLDB_LIBS+=";atomic"

TOOLCHAIN_FILE="$LLDB/cmake/platforms/Android.cmake"

CMAKE_OPTIONS+=(-GNinja)
CMAKE_OPTIONS+=("$LLVM")
CMAKE_OPTIONS+=(-Wno-dev)
CMAKE_OPTIONS+=(-DCMAKE_MAKE_PROGRAM="$NINJA")
CMAKE_OPTIONS+=(-DCMAKE_BUILD_TYPE=$CONFIG)
CMAKE_OPTIONS+=(-DCMAKE_TOOLCHAIN_FILE="$TOOLCHAIN_FILE")
CMAKE_OPTIONS+=(-DANDROID_TOOLCHAIN_DIR="$TOOLCHAIN")
CMAKE_OPTIONS+=(-DCMAKE_CXX_COMPILER_VERSION=4.9)
CMAKE_OPTIONS+=(-DANDROID_ABI=$ABI)
CMAKE_OPTIONS+=(-DLLVM_TARGET_ARCH=$LLVM_ARCH)
CMAKE_OPTIONS+=(-DLLVM_TARGETS_TO_BUILD=$LLVM_ARCH)
CMAKE_OPTIONS+=(-DLLVM_HOST_TRIPLE=$TRIPLE_ARCH-unknown-linux-android)
CMAKE_OPTIONS+=(-DLLVM_TABLEGEN="$HOST/bin/llvm-tblgen")
CMAKE_OPTIONS+=(-DCLANG_TABLEGEN="$HOST/bin/clang-tblgen")
CMAKE_OPTIONS+=(-DCMAKE_C_FLAGS="${LLDB_FLAGS[*]}")
CMAKE_OPTIONS+=(-DCMAKE_CXX_FLAGS="${LLDB_FLAGS[*]}")
CMAKE_OPTIONS+=(-DCMAKE_EXE_LINKER_FLAGS="${LLDB_LINKER_FLAGS[*]}")
CMAKE_OPTIONS+=(-DCMAKE_MODULE_LINKER_FLAGS="${LLDB_LINKER_FLAGS[*]}")
CMAKE_OPTIONS+=(-DCMAKE_SHARED_LINKER_FLAGS="${LLDB_LINKER_FLAGS[*]}")
CMAKE_OPTIONS+=(-DANDROID_SYSROOT="$SYSROOT")
CMAKE_OPTIONS+=(-DPYTHON_EXECUTABLE="$PYTHON_DIR/bin/python")
CMAKE_OPTIONS+=(-DLLDB_SYSTEM_LIBS="$LLDB_LIBS")
CMAKE_OPTIONS+=(-DLLVM_EXTERNAL_LLDB_SOURCE_DIR="$LLDB")
CMAKE_OPTIONS+=(-DLLVM_EXTERNAL_CLANG_SOURCE_DIR="$CLANG")

(cd "$BUILD" && "$CMAKE" "${CMAKE_OPTIONS[@]}")
"$NINJA" -C "$BUILD" lldb-server

mkdir -p "$INSTALL/android/$TRIPLE_ARCH"
cp -aL "$BUILD/bin/lldb-server" "$INSTALL/android/$TRIPLE_ARCH/"

done # for ARCH

(cd "$INSTALL/android" && zip --symlinks -r "$DEST/lldb-android-${BNUM}.zip" .)

#!/bin/bash
# Expected arguments:
# $1 = out_dir
# $2 = dest_dir
# $3 = build_number

# exit on error
set -e

# calculate the root directory from the script path
# this script lives two directories down from the root
# external/lldb-utils/build-linux.sh
ROOT_DIR="$(readlink -f "$(dirname "$0")/../..")"
cd "$ROOT_DIR"

function die() {
  echo "$*" > /dev/stderr
  echo "Usage: $0 <out_dir> <dest_dir> <build_number>" > /dev/stderr
  exit 1
}

(($# > 3)) && die "[$0] Unknown parameter: $4"

OUT="$1"
DEST="$2"
BNUM="$3"

[ ! "$OUT"  ] && die "## Error: Missing out folder"
[ ! "$DEST" ] && die "## Error: Missing destination folder"
[ ! "$BNUM" ] && die "## Error: Missing build number"

OUT="$(readlink -f "$OUT")"
DEST="$(readlink -f "$DEST")"

cat <<END_INFO
## Building android-studio ##
## Out Dir  : $OUT
## Dest Dir : $DEST
## Build Num: $BNUM

END_INFO

LLVM="$ROOT_DIR/external/llvm"
LLDB="$ROOT_DIR/external/lldb"

ln -fns ../../clang "$LLVM/tools/clang"
ln -fns ../../lldb "$LLVM/tools/lldb"

PRE="$ROOT_DIR/prebuilts"
CMAKE="$PRE/cmake/linux-x86/bin/cmake"
NINJA="$PRE/ninja/linux-x86/ninja"

export PATH="/usr/bin:/bin"
export SWIG_LIB="$PRE/swig/linux-x86/share/swig/2.0.11"

INSTALL="$OUT/lldb/install"
rm -rf "$INSTALL"

#######################
##### Linux build #####
#######################

CONFIG=Release

BUILD="$OUT/lldb/host"
rm -rf "$BUILD"
mkdir -p "$BUILD"

unset LLDB_FLAGS
unset CMAKE_OPTIONS

CLANG="$PRE/clang/linux-x86/host/3.6/bin/clang"
TOOLCHAIN="$PRE/gcc/linux-x86/host/x86_64-linux-glibc2.15-4.8"

LLDB_FLAGS+=(-fuse-ld=gold)
LLDB_FLAGS+=(-target x86_64-unknown-linux)
LLDB_FLAGS+=(-Qunused-arguments)

# Necessary because clang recognizes x86_64-linux-gnu
# as a valid gcc toolchain but not x86_64-linux.
find "$TOOLCHAIN" -name x86_64-linux -exec ln -fns {} {}-gnu \;
LLDB_FLAGS+=(--gcc-toolchain="$TOOLCHAIN")
LLDB_FLAGS+=(--sysroot="$TOOLCHAIN/sysroot")

# Prefix for gcc, ld, etc.
LLDB_FLAGS+=(-B"$TOOLCHAIN/bin/x86_64-linux-")

LLDB_FLAGS+=(-I"$PRE/libedit/linux-x86/include")
LLDB_FLAGS+=(-L"$PRE/libedit/linux-x86/lib")

CMAKE_OPTIONS+=(-GNinja)
CMAKE_OPTIONS+=("$LLVM")
CMAKE_OPTIONS+=(-Wno-dev)
CMAKE_OPTIONS+=(-DCMAKE_MAKE_PROGRAM="$NINJA")
CMAKE_OPTIONS+=(-DCMAKE_BUILD_TYPE=$CONFIG)
CMAKE_OPTIONS+=(-DCMAKE_C_COMPILER="$CLANG")
CMAKE_OPTIONS+=(-DCMAKE_CXX_COMPILER="$CLANG++")
CMAKE_OPTIONS+=(-DCMAKE_AR="$TOOLCHAIN/bin/x86_64-linux-ar")
CMAKE_OPTIONS+=(-DCMAKE_C_FLAGS="${LLDB_FLAGS[*]}")
CMAKE_OPTIONS+=(-DCMAKE_CXX_FLAGS="${LLDB_FLAGS[*]}")
CMAKE_OPTIONS+=(-DLLDB_DISABLE_CURSES=1)
CMAKE_OPTIONS+=(-DSWIG_EXECUTABLE="$PRE/swig/linux-x86/bin/swig")
CMAKE_OPTIONS+=(-DPYTHON_EXECUTABLE="$PRE/python/linux-x86/bin/python")
CMAKE_OPTIONS+=(-DPYTHON_LIBRARY="$PRE/python/linux-x86/lib/libpython2.7.so")
CMAKE_OPTIONS+=(-DPYTHON_INCLUDE_DIR="$PRE/python/linux-x86/include/python2.7")
CMAKE_OPTIONS+=(-DLLVM_TARGETS_TO_BUILD="ARM;X86;AArch64;Mips")
CMAKE_OPTIONS+=(-DCMAKE_INSTALL_PREFIX="$INSTALL/host")

(cd "$BUILD" && "$CMAKE" "${CMAKE_OPTIONS[@]}")
"$NINJA" -C "$BUILD" lldb lldb-server finish_swig lib/readline.so

# install target builds/installs 5G of stuff we don't need
#"$NINJA" -C "$BUILD" install

mkdir -p "$INSTALL/host/bin" "$INSTALL/host/lib" "$INSTALL/host/include/lldb"
cp -a "$BUILD/bin/"lldb*                           "$INSTALL/host/bin/"
cp -a "$BUILD/lib/"{liblldb.so*,readline.so}       "$INSTALL/host/lib/"
cp -a "$PRE/libedit/linux-x86/lib/"libedit.so*     "$INSTALL/host/lib/"
cp -a "$PRE/python/linux-x86/lib/"libpython2.7.so* "$INSTALL/host/lib/"
cp -a "$TOOLCHAIN/sysroot/usr/lib/"libtinfo.so*    "$INSTALL/host/lib/"
cp -a "$PRE/python/linux-x86/lib/python2.7"        "$INSTALL/host/lib/"
cp -a "$BUILD/lib/python2.7/site-packages"         "$INSTALL/host/lib/python2.7"
cp -a "$LLDB/include/lldb/"{API,Utility,lldb-*.h}  "$INSTALL/host/include/lldb/"

find "$INSTALL/host/include/lldb" -name 'lldb-private*.h' -exec rm {} +

unset PRUNE
PRUNE+=(-name '*.pyc')
PRUNE+=(-or -name '*.pyo')
PRUNE+=(-or -name 'plat-*')
PRUNE+=(-or -name 'config')
PRUNE+=(-or -name 'distutils')
PRUNE+=(-or -name 'idlelib')
PRUNE+=(-or -name 'lib2to3')
PRUNE+=(-or -name 'test')
PRUNE+=(-or -name 'unittest')
find "$INSTALL/host/lib/python2.7" '(' "${PRUNE[@]}" ')' -prune -exec rm -r {} +

#########################
##### Android build #####
#########################

CONFIG=MinSizeRel
HOST="$OUT/lldb/host"

for ARCH in x86 x86_64 arm aarch64 mips mips64; do

BUILD="$OUT/lldb/$ARCH"
rm -rf "$BUILD"
mkdir -p "$BUILD"

unset LLDB_FLAGS
unset LLDB_LIBS
unset CMAKE_OPTIONS

ABI=$ARCH
TRIPLE_ARCH=$ARCH
SYSROOT_ARCH=$ARCH
STL_ARCH=$ARCH

case $ARCH in
    x86)
        TOOLCHAIN="$PRE/gcc/linux-x86/x86/x86_64-linux-android-4.9"
        LLVM_ARCH=X86 TRIPLE_ARCH=i386 ABI=x86_64
        LLDB_FLAGS+=(-m32)
        ;;
    x86_64)
        TOOLCHAIN="$PRE/gcc/linux-x86/x86/x86_64-linux-android-4.9"
        LLVM_ARCH=X86
        ;;
    arm)
        TOOLCHAIN="$PRE/gcc/linux-x86/arm/arm-linux-androideabi-4.9"
        LLVM_ARCH=ARM STL_ARCH=armeabi-v7a ABI=armeabi
        ;;
    aarch64)
        TOOLCHAIN="$PRE/gcc/linux-x86/aarch64/aarch64-linux-android-4.9"
        LLVM_ARCH=AArch64 SYSROOT_ARCH=arm64 STL_ARCH=arm64-v8a
        ;;
    mips)
        TOOLCHAIN="$PRE/gcc/linux-x86/mips/mips64el-linux-android-4.9"
        LLVM_ARCH=Mips ABI=mips64
        LLDB_FLAGS+=(-mips32)
        ;;
    mips64)
        TOOLCHAIN="$PRE/gcc/linux-x86/mips/mips64el-linux-android-4.9"
        LLVM_ARCH=Mips
        ;;
esac

SYSROOT="$PRE/ndk/current/platforms/android-21/arch-$SYSROOT_ARCH"

# Necessary because mips64el-gcc searches paths relative to lib64.
[ $ARCH == mips ] && mkdir -p "$SYSROOT/usr/lib64"

STL="$PRE/ndk/current/sources/cxx-stl/gnu-libstdc++/4.9"

LLDB_FLAGS+=(-s) # stripped
LLDB_FLAGS+=(-I"$STL/include")
LLDB_FLAGS+=(-I"$STL/libs/$STL_ARCH/include")
LLDB_FLAGS+=(-L"$STL/libs/$STL_ARCH")

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
CMAKE_OPTIONS+=(-DANDROID_SYSROOT="$SYSROOT")
CMAKE_OPTIONS+=(-DPYTHON_EXECUTABLE="$PRE/python/linux-x86/bin/python")
CMAKE_OPTIONS+=(-DLLDB_SYSTEM_LIBS="$LLDB_LIBS")

(cd "$BUILD" && "$CMAKE" "${CMAKE_OPTIONS[@]}")
"$NINJA" -C "$BUILD" lldb-server

mkdir -p "$INSTALL/android/$TRIPLE_ARCH"
cp -aL "$BUILD/bin/lldb-server" "$INSTALL/android/$TRIPLE_ARCH/"

done # for ARCH

###############
##### ZIP #####
###############

mkdir -p "$DEST"
(cd "$LLDB" && zip --symlinks -r "$DEST/lldb-tests-${BNUM}.zip" test)
(cd "$INSTALL/host" && zip --symlinks -r "$DEST/lldb-linux-${BNUM}.zip" .)
(cd "$INSTALL/android" && zip --symlinks -r "$DEST/lldb-android-${BNUM}.zip" .)

#!/bin/bash
# Expected arguments:
# $1 = out_dir
# $2 = dist_dir
# $3 = build_number

# exit on error
set -e

# calculate the root directory from the script path
# this script lives two directories down from the root
# external/lldb-utils/build.sh
ROOT_DIR="$(dirname "$(dirname "$(dirname "$(realpath "$0")")")")"

function die() {
  echo "$*" > /dev/stderr
  echo "Usage: $0 <out_dir> <dest_dir> <build_number>" > /dev/stderr
  exit 1
}

while [[ -n "$1" ]]; do
  if [[ -z "$OUT" ]]; then
    OUT="$1"
  elif [[ -z "$DIST" ]]; then
    DIST="$1"
  elif [[ -z "$BNUM" ]]; then
    BNUM="$1"
  else
    die "[$0] Unknown parameter: $1"
  fi
  shift
done

if [[ -z "$OUT" ]]; then die "## Error: Missing out folder"; fi
if [[ -z "$DIST" ]]; then die "## Error: Missing destination folder"; fi
if [[ -z "$BNUM" ]]; then die "## Error: Missing build number"; fi

cd "$ROOT_DIR"

mkdir -p "$OUT"

# Dependencies:
# build
# sudo apt-get libedit-dev ncurses-dev python-dev
# test
# sudo apt-get libstdc++-4.8-dev:i386 lib32stdc++6-4.8-dbg libc++-dev:amd64 libc++-dev:i386

echo "## Building android-studio ##"
echo "## Dest dir : $DIST"
echo "## Qualifier: $QUAL"
echo "## Build Num: $BNUM"
echo

if [ -h external/llvm/tools/clang ]; then
    rm external/llvm/tools/clang
fi
if [ -h external/llvm/tools/lldb ]; then
    rm external/llvm/tools/lldb
fi

ln -s ../../clang external/llvm/tools/clang
ln -s ../../lldb external/llvm/tools/lldb

CONFIG=Release
PRE="$ROOT_DIR/prebuilts"
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
export PATH="$PRE/ninja/linux-x86:$PATH"
BUILD="$ROOT_DIR/$OUT/lldb/host"
rm -rf "$BUILD"
mkdir -p "$BUILD"
cd "$BUILD"
LLDB_FLAGS="-fuse-ld=gold -target x86_64-unknown-linux"
CLANG=$PRE/clang/linux-x86/host/3.6/bin/clang
export SWIG_LIB=$PRE/swig/linux-x86/share/swig/2.0.11/
INSTALL=$ROOT_DIR/$OUT/lldb/install
rm -rf $INSTALL || true

$PRE/cmake/linux-x86/bin/cmake -G Ninja \
-DCMAKE_BUILD_TYPE=$CONFIG \
-DCMAKE_C_COMPILER="$CLANG" \
-DCMAKE_CXX_COMPILER="$CLANG++" \
-DCMAKE_C_FLAGS="$LLDB_FLAGS" \
-DCMAKE_CXX_FLAGS="$LLDB_FLAGS" \
-DLLVM_TARGETS_TO_BUILD="ARM;X86;AArch64;Mips" \
-DSWIG_EXECUTABLE=$PRE/swig/linux-x86/bin/swig \
-DCMAKE_INSTALL_PREFIX=$INSTALL \
$ROOT_DIR/external/llvm

$PRE/ninja/linux-x86/ninja lldb lldb-server finish_swig lib/readline.so

# install target builds/installs 5G of stuff we don't need
#$PRE/ninja/linux-x86/ninja install

mkdir -p $INSTALL/bin
mkdir -p $INSTALL/lib
mkdir -p $INSTALL/include
cp -r lib/python2.7/ $INSTALL/lib/python2.7/
cp -a lib/liblldb.so* $INSTALL/lib/
cp lib/readline.so $INSTALL/lib/
cp bin/lldb $INSTALL/bin/
cp bin/lldb-server $INSTALL/bin/
cp -r ../../../external/lldb/include/lldb/API/ $INSTALL/include/LLDB

cd $ROOT_DIR/external/lldb/test
./dosep.py -o "-m --executable $INSTALL/bin/lldb -s $BUILD/traces"

mkdir -p $DIST
# zip file is 5.5GB, need to prune
(cd $INSTALL && zip --symlinks -r - ".") > "$DIST/lldb-linux-$BNUM.zip"


#!/bin/bash -x
# Expected arguments:
# $1 = out_dir
# $2 = dist_dir
# $3 = build_number

# exit on error
set -e

# OSX lacks a "realpath" bash command
realpath() {
    [[ $1 = /* ]] && echo "$1" || echo "$PWD/${1#./}"
}

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

echo "## Building android-studio ##"
echo "## Dest dir : $DIST"
echo "## Qualifier: $QUAL"
echo "## Build Num: $BNUM"
echo

ln -s ../../clang external/llvm/tools || true
ln -s ../llvm external/lldb || true

BUILD="$ROOT_DIR/$OUT/lldb/host"
rm -rf "$BUILD"
mkdir -p "$BUILD"

export SWIG_LIB=$PRE/swig/darwin-x86/share/swig/2.0.11/

CONFIG=Release
PRE="$ROOT_DIR/prebuilts"
export PATH="$PRE/swig/darwin-x86/bin:$PATH"
export SWIG_LIB=$PRE/swig/darwin-x86/share/swig/2.0.11/
cd $ROOT_DIR/external/lldb
xcodebuild -configuration $CONFIG -target desktop OBJROOT="$BUILD" SYMROOT="$BUILD"

cd $ROOT_DIR/external/lldb/test
./dosep.py -o "-m --executable $BUILD/$CONFIG/lldb -s $BUILD/traces"

mkdir -p $DIST
# zip file is huge, need to prune
find $BUILD/$CONFIG/LLDB.framework/ -name Clang -type d | xargs rm -rf
find $BUILD/$CONFIG/LLDB.framework/ -name debugserver | xargs rm
find $BUILD/$CONFIG/LLDB.framework/ -name lldb-server | xargs rm

(cd $BUILD/$CONFIG/ && zip -r --symlinks - lldb LLDB.framework) > "$DIST/lldb-mac-$BNUM.zip"

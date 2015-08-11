#!/bin/bash
# Expected arguments:
# $1 = out_dir
# $2 = dest_dir
# $3 = build_number

# exit on error
set -e

# OS X lacks a "realpath" bash command
realpath() {
    [[ "$1" == /* ]] && echo "$1" || echo "$PWD/$1"
}

# calculate the root directory from the script path
# this script lives two directories down from the root
# external/lldb-utils/build-darwin.sh
ROOT_DIR="$(realpath "$(dirname "$0")/../..")"
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

OUT="$(realpath "$OUT")"
DEST="$(realpath "$DEST")"

cat <<END_INFO
## Building android-studio ##
## Out Dir  : $OUT
## Dest Dir : $DEST
## Build Num: $BNUM

END_INFO

LLVM="$ROOT_DIR/external/llvm"
LLDB="$ROOT_DIR/external/lldb"

ln -fns ../../clang "$LLVM/tools/clang"
ln -fns ../llvm "$LLDB/llvm"

PRE="$ROOT_DIR/prebuilts"

export PATH="$PRE/swig/darwin-x86/bin:/usr/sbin:/usr/bin:/bin"
export SWIG_LIB="$PRE/swig/darwin-x86/share/swig/2.0.11"

CONFIG=Release

BUILD="$OUT/lldb/host"
rm -rf "$BUILD"
mkdir -p "$BUILD"

(cd "$LLDB" && xcodebuild -configuration $CONFIG -target desktop OBJROOT="$BUILD" SYMROOT="$BUILD")

# zip file is huge, need to prune
find "$BUILD/$CONFIG/LLDB.framework" -name Clang -or -name debugserver -or -name lldb-server -exec rm -rf {} +

mkdir -p "$DEST"
(cd "$BUILD/$CONFIG" && zip -r --symlinks "$DEST/lldb-mac-${BNUM}.zip" lldb LLDB.framework)

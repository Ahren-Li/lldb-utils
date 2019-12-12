#!/bin/bash
# Expected arguments:
# $1 = out_dir
# $2 = dest_dir
# $3 = build_number

# exit on error
set -e

# calculate the root directory from the script path
# this script lives two directories down from the root
# external/lldb-utils/build.sh
ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)
cd "$ROOT_DIR"

function die() {
	echo "$*" > /dev/stderr
	echo "Usage: $0 <out_dir> <dest_dir> <build_number>" > /dev/stderr
	exit 1
}

(($# > 3)) && die "[$0] Unknown parameter: $4"

OUT=$1
DEST=$2
BNUM=$3

[ ! "$OUT"  ] && die "## Error: Missing out folder"
[ ! "$DEST" ] && die "## Error: Missing destination folder"
[ ! "$BNUM" ] && die "## Error: Missing build number"

mkdir -p "$OUT" "$DEST"
OUT=$(cd "$OUT" && pwd -P)
DEST=$(cd "$DEST" && pwd -P)

cat <<END_INFO
## Building LLDB ##
## Out Dir  : $OUT
## Dest Dir : $DEST
## Build Num: $BNUM

END_INFO

LLVM=$ROOT_DIR/external/llvm-project/llvm
LLDB=$ROOT_DIR/external/llvm-project/lldb
CLANG=$ROOT_DIR/external/llvm-project/clang

PREBUILTS=$ROOT_DIR/prebuilts
NINJA_DIR=$PREBUILTS/ninja/$OS-x86
NINJA=$NINJA_DIR/ninja
CMAKE_DIR=$PREBUILTS/cmake/$OS-x86
CMAKE=$CMAKE_DIR/bin/cmake
SWIG_DIR=$PREBUILTS/swig/$OS-x86
PYTHON_DIR=$PREBUILTS/python/$OS-x86
CLANG_VERSION=$(cat "$LLDB_UTILS/config/clang.version")

export SWIG_LIB=$SWIG_DIR/share/swig/3.0.12

BUILD=$OUT/lldb/host
INSTALL=$OUT/lldb/install
rm -rf "$BUILD" "$INSTALL"
mkdir -p "$BUILD" "$INSTALL"

# print commands for easier debugging
set -x

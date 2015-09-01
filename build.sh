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
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
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

mkdir -p "$OUT" "$DEST"
OUT="$(cd "$OUT" && pwd)"
DEST="$(cd "$DEST" && pwd)"

cat <<END_INFO
## Building android-studio ##
## Out Dir  : $OUT
## Dest Dir : $DEST
## Build Num: $BNUM

END_INFO

LLVM="$ROOT_DIR/external/llvm"
LLDB="$ROOT_DIR/external/lldb"
CLANG="$ROOT_DIR/external/clang"

case "$(uname -s)" in
	Linux)  OS=linux;;
	Darwin) OS=darwin;;
	*_NT-*) OS=windows;;
esac

PREBUILTS="$ROOT_DIR/prebuilts"
NINJA="$PREBUILTS/ninja/${OS}-x86/ninja"
CMAKE="$PREBUILTS/cmake/${OS}-x86/bin/cmake"
SWIG_DIR="$PREBUILTS/swig/${OS}-x86"
PYTHON_DIR="$PREBUILTS/python/${OS}-x86"

export SWIG_LIB="$SWIG_DIR/share/swig/2.0.11"

BUILD="$OUT/lldb/host"
INSTALL="$OUT/lldb/install"
rm -rf "$BUILD" "$INSTALL"
mkdir -p "$BUILD" "$INSTALL"

source "$ROOT_DIR/external/lldb-utils/build-${OS}.sh"

if [ $OS == linux ]; then
	source "$ROOT_DIR/external/lldb-utils/build-android.sh"
	(cd "$LLDB" && zip --symlinks -r "$DEST/lldb-tests-${BNUM}.zip" test resources)
fi

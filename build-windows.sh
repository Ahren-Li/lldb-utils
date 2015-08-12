#!/bin/bash
# Expected arguments:
# $1 = out_dir
# $2 = dest_dir
# $3 = build_number
#
# Dependencies:
# cygwin zip

# exit on error
set -e

# calculate the root directory from the script path
# this script lives two directories down from the root
# external/lldb-utils/build-windows.sh
ROOT_DIR="$(cygpath -w "$(readlink -f "$(dirname "$0")/../..")")"
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

OUT="$(cygpath -w "$(readlink -f "$OUT")")"
DEST="$(cygpath -w "$(readlink -f "$DEST")")"

cat <<END_INFO
## Building android-studio ##
## Out Dir  : $OUT
## Dest Dir : $DEST
## Build Num: $BNUM

END_INFO

LLVM="$ROOT_DIR"'\external\llvm'
LLDB="$ROOT_DIR"'\external\lldb'
CLANG="$ROOT_DIR"'\external\clang'

PRE="$ROOT_DIR"'\prebuilts'
CMAKE="$PRE"'\cmake\windows-x86\bin\cmake'
NINJA="$PRE"'\ninja\windows-x86\ninja'

export SWIG_LIB="$PRE"'\swig\windows-x86\share\swig\2.0.11'

INSTALL="$OUT"'\lldb\install'
rm -rf "$INSTALL"

CONFIG=Release

BUILD="$OUT"'\lldb\host'
rm -rf "$BUILD"
mkdir -p "$BUILD"

unset CMAKE_OPTIONS
CMAKE_OPTIONS+=(-GNinja)
CMAKE_OPTIONS+=("$LLVM")
CMAKE_OPTIONS+=(-DCMAKE_BUILD_TYPE=$CONFIG)
CMAKE_OPTIONS+=(-DSWIG_DIR="$PRE"'\swig\windows-x86')
CMAKE_OPTIONS+=(-DSWIG_EXECUTABLE="$PRE"'\swig\windows-x86\bin\swig.exe')
CMAKE_OPTIONS+=(-DPYTHON_HOME="$PRE"'\python\windows-x86\x86')
CMAKE_OPTIONS+=(-DLLVM_TARGETS_TO_BUILD="ARM;X86;AArch64;Mips")
CMAKE_OPTIONS+=(-DCMAKE_INSTALL_PREFIX="$INSTALL"'\host')
CMAKE_OPTIONS+=(-DLLVM_EXTERNAL_LLDB_SOURCE_DIR="$LLDB")
CMAKE_OPTIONS+=(-DLLVM_EXTERNAL_CLANG_SOURCE_DIR="$CLANG")

unset CMD
CMD+=(cmd /c "${VS120COMNTOOLS}VsDevCmd.bat")
CMD+=('&&' cd "$BUILD")
CMD+=('&&' "$CMAKE" "${CMAKE_OPTIONS[@]}")
CMD+=('&&' "$NINJA" lldb finish_swig)

# Too large and missing site-packages - http://llvm.org/pr24378
#CMD+=('&&' "$NINJA" install)

PATH="$(cygpath -up "$(dirname "$NINJA")"';C:\Windows\system32')" "${CMD[@]}"

mkdir -p "$INSTALL/host/bin" "$INSTALL/host/lib" "$INSTALL/host/include/lldb"
cp -a "$BUILD/bin/"{lldb.exe,liblldb.dll}         "$INSTALL/host/bin/"
cp -a "$PRE/python/windows-x86/x86/python27.dll"  "$INSTALL/host/bin/"
cp -a "$BUILD/lib/"{liblldb.lib,site-packages}    "$INSTALL/host/lib/"
cp -a "$LLDB/include/lldb/"{API,Utility,lldb-*.h} "$INSTALL/host/include/lldb/"

find "$INSTALL/host/include/lldb" -name 'lldb-private*.h' -exec rm {} +

mkdir -p "$DEST"
(cd "$INSTALL/host" && zip -r "$DEST/lldb-windows-${BNUM}.zip" .)

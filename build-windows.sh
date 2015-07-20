#!/bin/bash
# Expected arguments:
# $1 = out_dir
# $2 = dist_dir
# $3 = build_number
#
# Dependencies:
# cygwin zip


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

echo "## Building android-studio ##"
echo "## Dest dir : $DIST"
echo "## Qualifier: $QUAL"
echo "## Build Num: $BNUM"
echo

mv external/clang external/llvm/tools/clang || true
mv external/lldb external/llvm/tools/lldb || true

CONFIG=Release
PRE="$ROOT_DIR/prebuilts"

export PATH="/cygdrive/c/Program Files (x86)/Microsoft Visual Studio 12.0/VC/bin":"/cygdrive/c/Program Files (x86)/Microsoft Visual Studio 12.0/Common7/IDE/":"/cygdrive/c/Program Files (x86)/Windows Kits/8.1/bin/x86":"$PATH"
export SWIG_LIB="D:\\src\\tmp\\prebuilts\\swig\\windows-x86\\share\\swig\\2.0.11"
export INCLUDE="C:\\Program Files (x86)\\Microsoft Visual Studio 12.0\\VC\\INCLUDE;C:\\Program Files (x86)\\Microsoft Visual Studio 12.0\\VC\\ATLMFC\\INCLUDE;C:\\Program Files (x86)\\Windows Kits\\8.1\\include\\shared;C:\\Program Files (x86)\\Windows Kits\\8.1\\include\\um;C:\\Program Files (x86)\\Windows Kits\\8.1\\include\\winrt;"
export LIB="C:\\Program Files (x86)\\Microsoft Visual Studio 12.0\\VC\\LIB;C:\\Program Files (x86)\\Microsoft Visual Studio 12.0\\VC\\ATLMFC\\LIB;C:\\Program Files (x86)\\Windows Kits\\8.1\\lib\\winv6.3\\um\\x86;"
export LIBPATH="C:\\Windows\\Microsoft.NET\\Framework\\v4.0.30319;C:\\Program Files (x86)\\Microsoft Visual Studio 12.0\\VC\\LIB;C:\\Program Files (x86)\\Microsoft Visual Studio 12.0\\VC\\ATLMFC\\LIB;C:\\Program Files (x86)\\Windows Kits\\8.1\\References\\CommonConfiguration\\Neutral;C:\\Program Files (x86)\\Microsoft SDKs\\Windows\\v8.1\\ExtensionSDKs\\Microsoft.VCLibs\\12.0\\References\\CommonConfiguration\\neutral;"

export PATH="$PRE/ninja/windows-x86/":"$PATH"

BUILD="$ROOT_DIR/$OUT/lldb/host"
rm -rf "$BUILD"
mkdir -p "$BUILD"
cd "$BUILD"
INSTALL=$ROOT_DIR/$OUT/lldb/install

export SWIG_LIB=$(cygpath -w $PRE/swig/windows-x86/share/swig/2.0.11/)

$PRE/cmake/windows-x86/bin/cmake -GNinja \
-DCMAKE_BUILD_TYPE=$CONFIG \
-DPYTHON_EXECUTABLE="$(cygpath -w $PRE/python/windows-x86/x86/python)" \
-DPYTHON_HOME="$(cygpath -w $PRE/python/windows-x86/x86)" \
-DLLVM_TARGETS_TO_BUILD="ARM;X86;AArch64;Mips" \
-DSWIG_DIR="$(cygpath -w $PRE/swig/windows-x86)" \
-DSWIG_EXECUTABLE="$(cygpath -w $PRE/swig/windows-x86/bin/swig)" \
-DCMAKE_INSTALL_PREFIX="$(cygpath -w $INSTALL)" \
"$(cygpath -w $ROOT_DIR/external/llvm)"

$PRE/ninja/windows-x86/ninja lldb finish_swig

$PRE/ninja/windows-x86/ninja install

#cd $ROOT_DIR/external/lldb/test
#./dosep.py -o "-m --executable $BUILD/bin/lldb -s $BUILD/traces"

mkdir -p $DIST
# zip file is 5.5GB, need to prune
#(cd $INSTALL && zip -r - ".") > "$DIST/lldb-windows-$BNUM.zip"

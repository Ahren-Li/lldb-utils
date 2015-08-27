#!/bin/bash
# Expected arguments:
# $1 = out_dir
# $2 = dest_dir
# $3 = build_number

# exit on error
set -e

if [ ! "${BASH_SOURCE[1]}" ]; then
	case "$(uname -s)" in
		*_NT-*)
			ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
			source "$ROOT_DIR/external/lldb-utils/build.sh" "$@"
			exit 0
			;;
		*)
			echo "No." > /dev/stderr
			exit 1
	esac
fi

# path too long
mkdir -p "$OUT/tmp"
mv "$LLVM" "$LLDB" "$CLANG" "$OUT/tmp/"
LLVM="$OUT/tmp/llvm"
LLDB="$OUT/tmp/lldb"
CLANG="$OUT/tmp/clang"

export SWIG_LIB="$(cygpath -w "$SWIG_LIB")"

CONFIG=Release

unset CMAKE_OPTIONS
CMAKE_OPTIONS+=(-GNinja)
CMAKE_OPTIONS+=("$(cygpath -w "$LLVM")")
CMAKE_OPTIONS+=(-DCMAKE_MAKE_PROGRAM="$(cygpath -w "${NINJA}.exe")")
CMAKE_OPTIONS+=(-DCMAKE_BUILD_TYPE=$CONFIG)
CMAKE_OPTIONS+=(-DSWIG_DIR="$(cygpath -w "$SWIG_DIR")")
CMAKE_OPTIONS+=(-DSWIG_EXECUTABLE="$(cygpath -w "$SWIG_DIR/bin/swig.exe")")
CMAKE_OPTIONS+=(-DLLDB_RELOCATABLE_PYTHON=1)
CMAKE_OPTIONS+=(-DPYTHON_HOME="$(cygpath -w "$PYTHON_DIR/x86")")
CMAKE_OPTIONS+=(-DLLVM_TARGETS_TO_BUILD="X86;ARM;AArch64;Mips;Hexagon")
CMAKE_OPTIONS+=(-DCMAKE_INSTALL_PREFIX="$(cygpath -w "$INSTALL/host")")
CMAKE_OPTIONS+=(-DLLVM_EXTERNAL_LLDB_SOURCE_DIR="$(cygpath -w "$LLDB")")
CMAKE_OPTIONS+=(-DLLVM_EXTERNAL_CLANG_SOURCE_DIR="$(cygpath -w "$CLANG")")

unset CMD
CMD+=(cmd /c "${VS120COMNTOOLS}VsDevCmd.bat")
CMD+=('&&' cd "$(cygpath -w "$BUILD")")
CMD+=('&&' "$(cygpath -w "${CMAKE}.exe")" "${CMAKE_OPTIONS[@]}")
CMD+=('&&' "$(cygpath -w "${NINJA}.exe")" lldb finish_swig)

# Too large and missing site-packages - http://llvm.org/pr24378
#CMD+=('&&' "$NINJA" install)

PATH="$(cygpath -u 'C:\Windows\System32')" "${CMD[@]}"

mkdir -p "$INSTALL/host/bin" "$INSTALL/host/lib" "$INSTALL/host/include/lldb"
cp -a "$BUILD/bin/"{lldb.exe,liblldb.dll}         "$INSTALL/host/bin/"
cp -a "$PYTHON_DIR/x86/python27.dll"              "$INSTALL/host/bin/"
cp -a "$BUILD/lib/"{liblldb.lib,site-packages}    "$INSTALL/host/lib/"
cp -a "$PYTHON_DIR/x86/Lib/"*                     "$INSTALL/host/lib/"
cp -a "$LLDB/include/lldb/"{API,Utility,lldb-*.h} "$INSTALL/host/include/lldb/"

find "$INSTALL/host/include/lldb" -name 'lldb-private*.h' -delete

unset PRUNE
PRUNE+=(-name '*.pyc')
PRUNE+=(-or -name 'plat-*')
PRUNE+=(-or -name 'distutils')
PRUNE+=(-or -name 'idlelib')
PRUNE+=(-or -name 'lib2to3')
PRUNE+=(-or -name 'test')
PRUNE+=(-or -name 'unittest')
find "$INSTALL/host/lib/" '(' "${PRUNE[@]}" ')' -prune -exec rm -r {} +

(cd "$INSTALL/host" && zip -r "$DEST/lldb-windows-${BNUM}.zip" .)

# move these back
mv "$LLVM" "$LLDB" "$CLANG" "$ROOT_DIR/external/"

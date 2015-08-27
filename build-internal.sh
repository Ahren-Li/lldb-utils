#!/bin/bash
# Expected arguments:
# $1 = out_dir
# $2 = dest_dir
# $3 = build_number

# exit on error
set -e

# calculate the root directory from the script path
# this script lives two directories down from the root
# external/lldb-utils/build-internal.sh
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "$ROOT_DIR/external/lldb-utils/build.sh" "$@"

GOOGLE="$ROOT_DIR/tools/vendor/google"
FRONTEND="$GOOGLE/android-ndk/native/LLDBProtobufFrontend"

CONFIG=Release

BUILD="$OUT/lldb/frontend"
rm -rf "$BUILD"
mkdir -p "$BUILD"

unset LLDB_FLAGS
unset LLDB_LINKER_FLAGS
unset CMAKE_OPTIONS

CMAKE_OPTIONS+=(-GNinja)
CMAKE_OPTIONS+=(-DCMAKE_BUILD_TYPE=$CONFIG)

case $OS in
	linux)
		CC="$PREBUILTS/clang/linux-x86/host/3.6/bin/clang"
		TOOLCHAIN="$PREBUILTS/gcc/linux-x86/host/x86_64-linux-glibc2.15-4.8"

		LLDB_FLAGS+=(-target x86_64-unknown-linux)
		LLDB_FLAGS+=(--gcc-toolchain="$TOOLCHAIN")
		LLDB_FLAGS+=(-B"$TOOLCHAIN/bin/x86_64-linux-")

		CMAKE_OPTIONS+=(-DCMAKE_SYSROOT="$TOOLCHAIN/sysroot")
		CMAKE_OPTIONS+=(-DCMAKE_C_COMPILER="$CC")
		CMAKE_OPTIONS+=(-DCMAKE_CXX_COMPILER="$CC++")
		CMAKE_OPTIONS+=(-DCMAKE_C_FLAGS="${LLDB_FLAGS[*]}")
		CMAKE_OPTIONS+=(-DCMAKE_CXX_FLAGS="${LLDB_FLAGS[*]}")

		CMAKE_OPTIONS+=("$FRONTEND")
		CMAKE_OPTIONS+=(-DCMAKE_MAKE_PROGRAM="$NINJA")
		CMAKE_OPTIONS+=(-DLIBLLDB_DIR="$INSTALL/host/lib")
		CMAKE_OPTIONS+=(-DCMAKE_INSTALL_PREFIX="$INSTALL/frontend")
		;;
	darwin)
		LLDB_FLAGS+=(-stdlib=libc++)
		LLDB_FLAGS+=(-mmacosx-version-min=10.8)

		LLDB_LINKER_FLAGS+=(-mmacosx-version-min=10.8)

		CMAKE_OPTIONS+=(-DCMAKE_C_COMPILER=clang)
		CMAKE_OPTIONS+=(-DCMAKE_CXX_COMPILER=clang++)
		CMAKE_OPTIONS+=(-DCMAKE_C_FLAGS="${LLDB_FLAGS[*]}")
		CMAKE_OPTIONS+=(-DCMAKE_CXX_FLAGS="${LLDB_FLAGS[*]}")
		CMAKE_OPTIONS+=(-DCMAKE_EXE_LINKER_FLAGS="${LLDB_LINKER_FLAGS[*]}")
		CMAKE_OPTIONS+=(-DCMAKE_MODULE_LINKER_FLAGS="${LLDB_LINKER_FLAGS[*]}")
		CMAKE_OPTIONS+=(-DCMAKE_SHARED_LINKER_FLAGS="${LLDB_LINKER_FLAGS[*]}")

		CMAKE_OPTIONS+=("$FRONTEND")
		CMAKE_OPTIONS+=(-DCMAKE_MAKE_PROGRAM="$NINJA")
		CMAKE_OPTIONS+=(-DLIBLLDB_DIR="$INSTALL/host")
		CMAKE_OPTIONS+=(-DCMAKE_INSTALL_PREFIX="$INSTALL/frontend")
		;;
	windows)
		# path too long
		TMP="$(mktemp -d)"
		mv "$ROOT_DIR/"{prebuilts,tools} "$TMP/"
		FRONTEND="$TMP${FRONTEND#"$ROOT_DIR"}"

		function finish() {
			# move these back
			mv "$TMP/"{prebuilts,tools} "$ROOT_DIR/"
			rmdir "$TMP"
		}

		trap finish EXIT

		CMAKE_OPTIONS+=("$(cygpath -w "$FRONTEND")")
		CMAKE_OPTIONS+=(-DCMAKE_MAKE_PROGRAM="$(cygpath -w "${NINJA}.exe")")
		CMAKE_OPTIONS+=(-DLIBLLDB_DIR="$(cygpath -w "$INSTALL/host/lib")")
		CMAKE_OPTIONS+=(-DCMAKE_INSTALL_PREFIX="$(cygpath -w "$INSTALL/frontend")")
		;;
esac

case $OS in
	windows)
		unset CMD
		CMD+=(cmd /c "${VS120COMNTOOLS}VsDevCmd.bat")
		CMD+=('&&' cd "$(cygpath -w "$BUILD")")
		CMD+=('&&' "$(cygpath -w "${CMAKE}.exe")" "${CMAKE_OPTIONS[@]}")
		CMD+=('&&' "$(cygpath -w "${NINJA}.exe")" install)
		PATH="$(cygpath -u 'C:\Windows\System32')" "${CMD[@]}"
		;;
	*)
		(cd "$BUILD" && "$CMAKE" "${CMAKE_OPTIONS[@]}")
		"$NINJA" -C "$BUILD" install
		;;
esac

(cd "$INSTALL/frontend" && zip -r "$DEST/lldb-frontend-$OS-${BNUM}.zip" .)

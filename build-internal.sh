#!/bin/bash
# Expected arguments:
# $1 = out_dir
# $2 = dest_dir
# $3 = build_number

case "$(uname -s)" in
	Linux)  OS=linux;;
	Darwin) OS=darwin;;
	*_NT-*) OS=windows;;
esac

source build-${OS}.sh "$@"

GOOGLE="$ROOT_DIR/tools/vendor/google"
FRONTEND="$GOOGLE/android-ndk/native/LLDBProtobufFrontend"

CONFIG=Release

BUILD="$OUT/lldb/frontend"
rm -rf "$BUILD"
mkdir -p "$BUILD"

unset LLDB_FLAGS
unset CMAKE_OPTIONS

case $OS in
	linux)
		CLANG="$PRE/clang/linux-x86/host/3.6/bin/clang"
		TOOLCHAIN="$PRE/gcc/linux-x86/host/x86_64-linux-glibc2.15-4.8"

		LLDB_FLAGS+=(-target x86_64-unknown-linux)
		LLDB_FLAGS+=(--gcc-toolchain="$TOOLCHAIN")
		LLDB_FLAGS+=(-B"$TOOLCHAIN/bin/x86_64-linux-")

		CMAKE_OPTIONS+=(-DCMAKE_SYSROOT="$TOOLCHAIN/sysroot")
		CMAKE_OPTIONS+=(-DCMAKE_C_COMPILER="$CLANG")
		CMAKE_OPTIONS+=(-DCMAKE_CXX_COMPILER="$CLANG++")
		CMAKE_OPTIONS+=(-DCMAKE_C_FLAGS="${LLDB_FLAGS[*]}")
		CMAKE_OPTIONS+=(-DCMAKE_CXX_FLAGS="${LLDB_FLAGS[*]}")
		;;
	darwin)
		LLDB_FLAGS+=(-stdlib=libc++)
		LLDB_FLAGS+=(-mmacosx-version-min=10.8)

		CMAKE_OPTIONS+=(-DCMAKE_C_COMPILER=clang)
		CMAKE_OPTIONS+=(-DCMAKE_CXX_COMPILER=clang++)
		CMAKE_OPTIONS+=(-DCMAKE_C_FLAGS="${LLDB_FLAGS[*]}")
		CMAKE_OPTIONS+=(-DCMAKE_CXX_FLAGS="${LLDB_FLAGS[*]}")
		;;
esac

NINJA="$PRE/ninja/$OS-x86/ninja"
CMAKE="$PRE/cmake/$OS-x86/bin/cmake"

case $OS in
	darwin) CMAKE_OPTIONS+=(-DLIBLLDB_DIR="$INSTALL/host");;
	*)      CMAKE_OPTIONS+=(-DLIBLLDB_DIR="$INSTALL/host/lib");;
esac

CMAKE_OPTIONS+=(-GNinja)
CMAKE_OPTIONS+=("$FRONTEND")
CMAKE_OPTIONS+=(-DCMAKE_MAKE_PROGRAM="$NINJA")
CMAKE_OPTIONS+=(-DCMAKE_BUILD_TYPE=$CONFIG)
CMAKE_OPTIONS+=(-DCMAKE_INSTALL_PREFIX="$INSTALL/frontend")

case $OS in
	windows)
		unset CMD
		CMD+=(cmd /c "${VS120COMNTOOLS}VsDevCmd.bat")
		CMD+=('&&' cd "$BUILD")
		CMD+=('&&' "$CMAKE" "${CMAKE_OPTIONS[@]}")
		CMD+=('&&' "$NINJA" install)
		PATH="$(cygpath -up 'C:\Windows\system32')" "${CMD[@]}"
		;;
	*)
		(cd "$BUILD" && "$CMAKE" "${CMAKE_OPTIONS[@]}")
		"$NINJA" -C "$BUILD" install
		;;
esac

(cd "$INSTALL/frontend" && zip -r "$DEST/lldb-frontend-$OS-${BNUM}.zip" .)

#!/bin/bash
# Expected arguments:
# $1 = out_dir
# $2 = dest_dir
# $3 = build_number

# exit on error
set -e

if [ ! "${BASH_SOURCE[1]}" ]; then
	ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
	source "$ROOT_DIR/external/lldb-utils/build.sh" "$@"
	exit
fi

ln -fns ../llvm "$LLDB/llvm"
ln -fns ../../clang "$LLVM/tools/clang"

export PATH="$SWIG_DIR/bin:/usr/sbin:/usr/bin:/bin"

CONFIG=Release

unset XCODEBUILD_OPTIONS
unset PRUNE

XCODEBUILD_OPTIONS+=(-configuration $CONFIG)
XCODEBUILD_OPTIONS+=(-target desktop)
XCODEBUILD_OPTIONS+=(OBJROOT="$BUILD")
XCODEBUILD_OPTIONS+=(SYMROOT="$BUILD")

(cd "$LLDB" && xcodebuild "${XCODEBUILD_OPTIONS[@]}")

mkdir -p "$INSTALL/host" "$INSTALL/host/include/lldb"
cp -a "$BUILD/$CONFIG/"{lldb,LLDB.framework}      "$INSTALL/host/"
cp -a "$LLDB/include/lldb/"{API,Utility,lldb-*.h} "$INSTALL/host/include/lldb/"

find "$INSTALL/host/include/lldb" -name 'lldb-private*.h' -delete

unset PRUNE
PRUNE+=('(' -name Clang -and -type d ')')
PRUNE+=( -or -name argdumper)
PRUNE+=( -or -name darwin-debug)
PRUNE+=( -or -name lldb-server)

# zip file is huge, need to prune
find "$INSTALL/host/LLDB.framework" '(' "${PRUNE[@]}" ')' -exec rm -rf {} +

(cd "$INSTALL/host" && zip -r --symlinks "$DEST/lldb-mac-${BNUM}.zip" .)

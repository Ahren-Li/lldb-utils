#!/bin/bash
# Expected arguments:
# $1 = out_dir
# $2 = dest_dir
# $3 = build_number

OS=windows

LLDB_UTILS=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)
source "$LLDB_UTILS/build-common.sh" "$@"

# fix-up clang
# We need to add the clang-cl.exe -> clang.exe symlink,
# but we don't want to dirty the source repository.
# So, copy the whole subtree into our build folder.
rm -rf "$OUT/clang"
cp -va "$ROOT_DIR/prebuilts/clang/host/windows-x86/clang-${CLANG_VERSION}" "$OUT/clang"
cp -va "$OUT/clang/bin/clang.exe" "$OUT/clang/bin/clang-cl.exe"

export SWIG_LIB=$(cygpath --windows "$SWIG_LIB")

unset CMAKE_OPTIONS
CMAKE_OPTIONS+=(-C"$(cygpath --windows "$LLDB_UTILS/config/$OS.cmake")")
CMAKE_OPTIONS+=(-H"$(cygpath --windows "$LLVM")")
CMAKE_OPTIONS+=(-B"$(cygpath --windows "$BUILD")")

cat > "$OUT/commands.bat" <<-EOF
	set PATH=C:\\Windows\\System32
	set CMAKE=$(cygpath --windows "${CMAKE}.exe")
	set BUILD=$(cygpath --windows "$BUILD")
	set INSTALL=$(cygpath --windows "$INSTALL/host")
	set PATH=C:\Program Files (x86)\Windows Kits\10\bin\\$WINDOWS_SDK_VERSION\x64;%PATH%
	call "${VS140COMNTOOLS}\\..\\..\\VC\\vcvarsall.bat" amd64
	"%CMAKE%" $(printf '"%s" ' "${CMAKE_OPTIONS[@]}")
	"%CMAKE%" --build "%BUILD%" --target lldb
	"%CMAKE%" --build "%BUILD%" --target llvm-symbolizer
	"%CMAKE%" --build "%BUILD%" --target finish_swig
	@rem Too large and missing site-packages - http://llvm.org/pr24378
	@rem set DESTDIR=%INSTALL%
	@rem "%CMAKE%" --build "%BUILD%" --target install
EOF

cat "$OUT/commands.bat"
cmd /c "$(cygpath --windows "$OUT/commands.bat")"
rm "$OUT/commands.bat"

mkdir -p "$INSTALL/host/"{bin,lib,include/lldb,include/LLDB,dlls}
cp -a "$BUILD/bin/"{lldb.exe,liblldb.dll,llvm-symbolizer.exe}   "$INSTALL/host/bin/"
cp -a "$PYTHON_DIR/x64/"{python.exe,python27.dll} "$INSTALL/host/bin/"
cp -a "$BUILD/lib/"{liblldb.lib,site-packages}    "$INSTALL/host/lib/"
cp -a "$PYTHON_DIR/x64/Lib/"*                     "$INSTALL/host/lib/"
cp -a "$PYTHON_DIR/x64/DLLs/"*.pyd                "$INSTALL/host/dlls/"
cp -a "$LLDB/include/lldb/API/"*                  "$INSTALL/host/include/LLDB/"
cp -a "$LLDB/include/lldb/"{API,Utility,lldb-*.h} "$INSTALL/host/include/lldb/"

find "$INSTALL/host/include/lldb" -name 'lldb-private*.h' -delete

unset PRUNE
PRUNE+=(-name '*.pyc')
PRUNE+=(-or -name 'plat-*')
PRUNE+=(-or -name 'idlelib')
PRUNE+=(-or -name 'lib2to3')
PRUNE+=(-or -name 'test')
find "$INSTALL/host/lib/" '(' "${PRUNE[@]}" ')' -prune -exec rm -r {} +

pushd "$INSTALL/host"
zip --filesync --recurse-paths "$DEST/lldb-windows-$BNUM.zip" .
popd

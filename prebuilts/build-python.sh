#!/bin/bash -ex
# latest version of this file can be found at 
# https://android.googlesource.com/platform/external/lldb-utils
#
# Download & build swig on the local machine
# works on Linux, OSX, and Windows (Cygwin)
# leaves output in /tmp/prebuilts/install/

PROJ=python
VER=2.7.10
MSVS=2013

source $(dirname "$0")/build-common.sh build-common.sh

BASE=Python-$VER
TGZ=$BASE.tgz
curl -L https://www.python.org/ftp/python/$VER/$TGZ -o $TGZ
tar xzf $TGZ || cat $TGZ # if this fails, we're probably getting an http error
cd $BASE

case "$OS" in
windows)
	cp PC/pyconfig.h Include
	devenv.com PCbuild/pcbuild.sln /Upgrade
	# some projects will fail and that's okay
    devenv.com PCbuild/pcbuild.sln /Build Debug /Out log.txt || egrep -c "========== Build: 18 succeeded, 7 failed, 0 up-to-date, 1 skipped ==========" log.txt
    devenv.com PCbuild/pcbuild.sln /Build Release /Out log.txt || egrep -c "========== Build: 17 succeeded, 7 failed, 1 up-to-date, 1 skipped ==========" log.txt
	devenv.com PCbuild/pcbuild.sln /Build "Release|x64" /Out log.txt || egrep -c "========== Build: 16 succeeded, 7 failed, 2 up-to-date, 1 skipped ==========" log.txt
	devenv.com PCbuild/pcbuild.sln /Build "Debug|x64" /Out log.txt || egrep -c "========== Build: 16 succeeded, 7 failed, 2 up-to-date, 1 skipped ==========" log.txt
	curl -L http://llvm.org/svn/llvm-project/lldb/trunk/scripts/install_custom_python.py -o install_custom_python.py
	python install_custom_python.py --source "$(cygpath -w $RD/Python-$VER)" --dest "$(cygpath -w $INSTALL)" --overwrite --silent
	;;
linux|darwin)
    # can't get prebuilt clang working https://b/22748915
	mkdir $RD/build
	cd $RD/build
	$RD/$BASE/configure --prefix=$INSTALL --enable-unicode=ucs4 --enable-shared
	make -j$CORES
	make install
	;;
esac

commit_and_push


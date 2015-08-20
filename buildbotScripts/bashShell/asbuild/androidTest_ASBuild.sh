#!/bin/bash -e
config=(${1//,/ })
export deviceId=${config[0]}
export compiler=${config[1]}
export arch=${config[2]}
function clean {
  adb -s $deviceId shell ps | grep lldb-server | awk '{print $2}' | xargs adb -s $deviceId shell kill
  adb -s $deviceId shell rm -rf $remoteDir
}
trap clean EXIT

set -x
adb -s $deviceId shell getprop ro.build.fingerprint
adb -s $deviceId shell rm -rf $remoteDir || true
adb -s $deviceId shell mkdir $remoteDir
adb -s $deviceId push $buildDir/$arch/lldb-server $remoteDir/
adb forward --remove-all
screen -d -m adb -s $deviceId shell TMPDIR=$remoteDir/tmp $remoteDir/lldb-server platform --listen 127.0.0.1:$port --server

export LLDB_TEST_THREADS=8

apilevel=$(adb -s $deviceId shell getprop ro.build.version.sdk)
apilevel=${apilevel//[[:space:]]/}

cmd="$lldbDir/test/dosep.py --options '\
--executable $buildDir/bin/lldb \
-A $arch -C $toolchain/$arch-$apilevel/bin/$compiler \
-s logs-$compiler-$arch -u CXXFLAGS -u CFLAGS \
--channel \"gdb-remote packets\" --channel \"lldb all\" \
--platform-name remote-android \
--platform-url adb://$deviceId:$port \
--platform-working-dir $remoteDir \
--env OS=Android -m'"

eval $cmd

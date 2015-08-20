#!/bin/bash
export originalDir=$(pwd)
export rootDir=$(pwd)/..
export lldbDir=$rootDir/lldb
export buildDir=$rootDir/build
export remoteDir=/data/local/tmp/lldb
export toolchain=$HOME/Toolchains
export gstrace=gs://lldb_test_traces_asbuild
export gs_asbin_linux=gs://lldb_asbuild_binaries/builds/git_studio-1.4-dev-linux-lldb_linux
export gs_asbin_darwin=gs://lldb_asbuild_binaries/builds/git_studio-1.4-dev-mac-lldb_darwin
export port=5430
if [ $(uname) == Darwin ]
then
  export DYLD_FRAMEWORK_PATH=$lldbDir/build/Release
fi

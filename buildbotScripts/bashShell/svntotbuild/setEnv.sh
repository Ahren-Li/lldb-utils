#!/bin/bash
export originalDir=$(pwd)
export rootDir=$(pwd)/..
export buildDir=$rootDir/build
export remoteDir=/data/local/tmp/lldb
export toolchain=$HOME/Toolchains
export port=5430
export gstrace=gs://lldb_test_traces
export gsbinaries=gs://lldb_binaries
if [ $(uname) == Darwin ]
then
  export lldbDir=$rootDir/lldb
  export llvmDir=$lldbDir/llvm
  export clangDir=$llvmDir/tools/clang
  export DYLD_FRAMEWORK_PATH=$lldbDir/build/Release
else
  export llvmDir=$rootDir/llvm
  export lldbDir=$llvmDir/tools/lldb
  export clangDir=$llvmDir/tools/clang
fi
export lockDir=/var/tmp/lldbbuild.exclusivelock

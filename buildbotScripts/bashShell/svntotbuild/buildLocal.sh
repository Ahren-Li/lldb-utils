#!/bin/bash -e
source setEnv.sh
host=$(uname)
if [[ $host == Darwin ]];
then
  cd $lldbDir
  set +x
  security unlock-keychain -p 'cat ~/.keychain_password' /Users/lldb_build/Library/Keychains/login.keychain
  set -x
  cmd=xcrun xcodebuild -target desktop -configuration Release build
  $cmd || $cmd
else
  set -x
  cd $buildDir
  nice -n 10 ninja -j40
fi


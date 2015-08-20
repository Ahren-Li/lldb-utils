#!/bin/bash
source setEnv.sh

if [ -d "$lldbDir" ] && [ $(uname) == Darwin ]
then
  cd $lldbDir
  rm -rf $buildDir
  cmd=xcrun xcodebuild -target desktop -configuration Release clean
else
  rm -rf $buildDir
fi
echo clean build dir

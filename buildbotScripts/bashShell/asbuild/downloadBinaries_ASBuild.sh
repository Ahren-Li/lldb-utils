#!/bin/bash -e
source setEnv_ASBuild.sh
set -x
cd $rootDir

gsutil cp -r $gs_asbin_linux/$1/** .
unzip -o lldb-tests-* -d $lldbDir/
unzip -o lldb-android-* -d $buildDir/

if [ $(uname) == Darwin ]
then
  gsutil cp -r $gs_asbin_darwin/$1/** .
  unzip -o lldb-mac-* -d $buildDir/bin/
else
  unzip -o lldb-android-* -d $buildDir/
fi

rm -f *.zip

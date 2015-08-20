#!/bin/bash -e
source setEnv.sh

rev=$(svnversion $llvmDir)
cd $rootDir
zip -r rev-$rev build/android-*/bin
gsutil cp rev-$rev.zip $gsbinaries/
rm rev-$rev.zip

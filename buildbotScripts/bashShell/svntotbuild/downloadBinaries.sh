#!/usr/bin/env bash
set -e
source setEnv.sh
rev=$1

cd $rootDir
gsutil cp $gsbinaries/rev-$rev.zip .
cd "$buildDir"
unzip -o rev-$rev.zip
rm -f rev-$rev.zip

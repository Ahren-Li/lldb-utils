#!/bin/bash
source setEnv_ASBuild.sh
set -x
cd $rootDir
zipCmd="zip -r build-$1 $originalDir/logs-"'*'""
rmCmd="rm -rf $originalDir/logs-"'*'""

eval $zipCmd
gsutil mv build-$1.zip $gstrace/$2/

oldNum=$(( $1-500 ))
echo remove old test trace of build $oldNum
gsutil rm $gstrace/$2/build-$oldNum.zip || true
eval $rmCmd

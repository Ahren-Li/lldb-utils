#!/bin/bash -e
source setEnv_ASBuild.sh
if [ $1 == local* ]
then
  source localTest.sh $1
else
  source androidTest_ASBuild.sh $1
fi

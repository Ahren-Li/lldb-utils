#!/bin/bash -e
source setEnv.sh
if [[ $1 == local* ]];
then
  source localTest.sh $1
else
  source androidTest.sh $1
fi

#!/bin/bash -e
set -x
host=$(uname)
if [[ $host != Linux ]];
then
  echo "Skip cmake step for" $host
else
  source setEnv.sh
  mkdir -p $buildDir
  cd $buildDir
  cmake -GNinja -DCMAKE_BUILD_TYPE=Release $llvmDir -DCMAKE_C_COMPILER=clang -DCMAKE_CXX_COMPILER=clang++
fi

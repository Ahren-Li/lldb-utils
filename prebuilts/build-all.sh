#!/bin/bash -ex
./build-python.sh
./build-editline.sh
./build-swig.sh
./build-cmake.sh
./build-ninja.sh
./build-glog.sh
./build-protobuf.sh

#!/bin/bash -e
config=(${1//,/ })

compiler=${config[1]}
arch=${config[2]}

if [ $compiler == "totclang" ]
then
  compiler=$buildDir/bin/clang
fi

host=$(uname)
echo "uname: " $host
if [ $host == Darwin ]
then
  cmd="$lldbDir/test/dotest.py \
--executable $lldbDir/build/Release/lldb \
--framework $lldbDir/build/Release/LLDB.framework \
-A $arch -C $compiler \
-s logs-${config[1]}-$arch \
-u CXXFLAGS -u CFLAGS"
else
  cmd="$lldbDir/test/dotest.py \
--executable $buildDir/bin/lldb \
-A $arch -C $compiler \
-s logs-${config[1]}-$arch \
-u CXXFLAGS -u CFLAGS \
--channel \"gdb-remote packets\" \
--channel \"lldb all\""
fi

echo $cmd
eval $cmd
svn status $lldbDir/test --no-ignore | grep '^[I?]' | cut -c 9- | while IFS= read -r f; do echo "$f"; rm -rf "$f"; done

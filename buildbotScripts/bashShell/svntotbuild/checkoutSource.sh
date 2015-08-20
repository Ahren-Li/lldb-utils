#!/bin/bash -e
source setEnv.sh
source cleanUp.sh

export llvmsvn=http://llvm.org/svn/llvm-project/llvm/trunk
export clangsvn=http://llvm.org/svn/llvm-project/cfe/trunk
export lldbsvn=http://llvm.org/svn/llvm-project/lldb/trunk

if [ "$1" == "" ]; then
    export rev=HEAD
else
    export rev=$1
fi

function svnFunc {
  if [ -d "$1/.svn" ]; then
      svn cleanup $1
      svn update --non-interactive --no-auth-cache --revision $rev $1
  else
      svn checkout --non-interactive --no-auth-cache --revision $rev $2@$rev $1
  fi
}

svnFunc $llvmDir $llvmsvn
svnFunc $clangDir $clangsvn
svnFunc $lldbDir $lldbsvn


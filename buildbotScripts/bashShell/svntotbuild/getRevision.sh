#!/bin/bash -e
source setEnv.sh
# turn off echo of commands
# the entire output of this script will be used to set got_revision property of buildbot
# nothing but the revision number should be output by this script
set +x
echo $(svnversion $llvmDir)

#!/bin/bash -e

# This script ensures that only one build is running at a time
# Work flow,
# if make lock dir successfully, mark lock owner and start build
# if lock dir already exist, then check lock owner,
#   if lock owner is current builder, then start build - this means last build terminated unexpectedly, lock was not released
#   if lock owner is not current builder, keep polling until lock is released by other builders

source setEnv.sh
function startBuild {
  echo $1 make dir successfully, start build
  echo $1 > $lockDir/lock.txt
}

# when there are pending build requests in the queue, next build starts immediatly
# wait for 5 seconds, allow other builder to have the chance to acquire lock if any
sleep 5

if mkdir $lockDir
then
  startBuild $1
else
  owner=$(cat $lockDir/lock.txt)
  echo Lock owner is $owner
  if [ "$owner" == "$1" ]; then
    echo I am owner, start build
  else
    echo I am not owner, wait for lock release ...
    while :
    do
      if mkdir $lockDir
      then
        startBuild $1
        exit 0
      else
        echo sleep three seconds, check again ...
        sleep 3
      fi
    done
  fi
fi

import re
import os
import collections
import zipfile
import argparse
from collections import defaultdict
from subprocess import call
import subprocess

def get_args():
  parser = argparse.ArgumentParser(description='Parse test logs')
  parser.add_argument('-f', '--from', type=int, dest="f", action='store',
                      help='build number to parse start from')
  parser.add_argument('-t', '--to', type=int, dest='t', action='store',
                      help='build number to parse until')
  parser.add_argument('-n', '--number', type=int, dest='singleBuild', action='store',
                      help='single build number to parse')
  parser.add_argument('-b', '--builder', type=str, dest='builder', action='store', required=True,
                      choices=['darwin', 'android', 'cmake', 'windows'],
                      help='builder to parse, available: cmake, android, darwin, windows')
  parser.add_argument('-d', '--dir', type=str, dest='dir', action='store',
                      help='directory to store downloaded logs')
  parser.add_argument('-v', '--verbose', dest='v', action='count',
                      help='display build number for each result')
  parser.add_argument('-c', '--count', type=int, dest='count', action='store',
                      help='display the last N results')
  args = parser.parse_args()
  if((args.f is None or args.t is None) and args.count is None):
    parser.error("-c or -f & -t is required")
  if(args.f is not None and (args.t is not None or args.count is not None)):
    parser.error("either -c or -f & -t is permitted, not both")
  return args

resultInfo = collections.namedtuple("resultInfo", ["build", "arch", "compiler"])
logDestDir = "logs/"
logSourceDirDict = {"darwin":"gs://lldb_test_traces/lldb-x86_64-darwin-13.4/",
                    "cmake":"gs://lldb_test_traces/lldb-x86_64-ubuntu-14.04-cmake/",
                    "android":"gs://lldb_test_traces/lldb-x86_64-ubuntu-14.04-android/",
                    "windows":"gs://lldb_test_traces/lldb-windows7-android"}
configDict = {"darwin":2,
              "cmake":6,
              "android":3,
              "windows":1}
logSourceDir = ""
gsutil = '/usr/bin/gsutil'
# whether include test method in the result or not,
# if True: TestMiExec.MiExecTestCase.test_lldbmi_exec_step (90.717949%)
# if False: TestMiExec (98.717949%), set to True for now,
# because False will produce inaccurate percentage count, need to make sure each testSuite only counted once for each build
printTestMethod = True
if printTestMethod:
  fileNameRE = re.compile(r'^(.*)-(.*\..*\..*)-(.*)-(.*)\.log')
  timeoutNameRE = re.compile(r'^(.*\..*\..*)-(.*)-(.*)\.log')
else:
  fileNameRE = re.compile(r'^(.*)-(.*)\..*\..*-(.*)-(.*)\.log')
  timeoutNameRE = re.compile(r'^(.*)\..*\..*-(.*)-(.*)\.log')
totalParsed = 0

skipList = set()
upassList = set()
xfailList = set()
hangList = set()
hangDict = defaultdict(list)
skipDict = defaultdict(list)
upassDict = defaultdict(list)
xfailDict = defaultdict(list)
failDict = defaultdict(list)

def getServerFileList():
  filelist = subprocess.check_output([gsutil, 'ls', logSourceDir]).splitlines()
  return filelist

def downloadAndParseLastNFiles(filelist, count):
  lastN = min(count, len(filelist))
  for file in filelist[-lastN:]:
    buildNum = getBuild(file)
    dest = logDestDir + "build-%s.zip" % buildNum
    if not os.path.isfile(dest):
      call([gsutil, 'cp', file, logDestDir])
    # check file downloaded successfully
    if os.path.isfile(dest):
      parseZip(dest)

def downloadAndParseRangeFiles(start, end):
  for buildNum in range(start, end+1):
    source = logSourceDir + "build-%d.zip" % buildNum
    dest = logDestDir + "build-%d.zip" % buildNum
    if not os.path.isfile(dest):
      call([gsutil, 'cp', source, logDestDir])
    # still need to check file existence because the log might not exist on server for current build
    if os.path.isfile(dest):
      parseZip(dest)

def getBuild(zipName):
  m = re.match(r'^(.*)build-(.*)\.zip', zipName)
  return m.groups()[1]

# TODO: once
def parseZip(zipName):
  global totalParsed
  totalParsed += 1
  myzip = zipfile.ZipFile(zipName,"r")
  build = getBuild(zipName)
  namelist = myzip.namelist()

  for name in namelist:
    if(name.endswith('.log') and not (name.endswith('host.log') or name.endswith('server.log'))):
      #print 'filename: ', name
      name = os.path.basename(name)
      m = fileNameRE.match(name)
      if m:
        code, test, arch, compiler = m.groups()
        # totclang, the RE format does't apply
        if compiler.find('_')>-1:
          compiler = 'totclang'
          arch = test.split('-')[1]
          test = test.split('-')[0]
        info = resultInfo(build, arch, compiler)
        #print code, test, arch, compiler
        if code == 'ExpectedFailure':
          xfailList.add(test)
          xfailDict[test].append(info)
        elif code == 'SkippedTest':
          skipList.add(test)
          skipDict[test].append(info)
        elif code == 'UnexpectedSuccess':
          upassList.add(test)
          upassDict[test].append(info)
        elif code == 'Failure':
          failDict[test].append(info)
      else:
        m = timeoutNameRE.match(name)
        if m:
          test, arch, compiler = m.groups()
          info = resultInfo(build, arch, compiler)
          hangList.add(test)
          hangDict[test].append(info)

# TODO: verbose level
# disable verbose for xfail, xpass and skip
def addResult(dict, build, test, arch, compiler):
  return
def printDict(dict, verbose):
  for k,v in dict.items():
    if verbose is None:
      print k, '(%d/%d %f%%)' % (len(v), totalParsed, 100.0*len(v)/totalParsed)
    if verbose is 1:
      print k, '(%d/%d %f%%)' % (len(v), totalParsed, 100.0*len(v)/totalParsed)
    if verbose is 2:
      print k, v

def printResult(v):
  print "\nTimeout/Exception:"
  printDict(hangDict, v)

  print "\nUnexpectedPass:"
  printDict(upassDict, None)

  print "\nExpectedFailure:"
  printDict(xfailDict, None)

  print "\nSkippedTest:"
  printDict(skipDict, None)

  print "\nFailure:"
  printDict(failDict, v)

def main():
  global logDestDir, logSourceDir, totalParsed

  args = get_args()
  if(args.dir is None):
    logDestDir = os.path.dirname(os.path.abspath(__file__)) + '/logs/%s/'%args.builder
  logSourceDir = logSourceDirDict[args.builder]
  if not os.path.exists(logDestDir):
    os.makedirs(logDestDir)
  getServerFileList()
  if(args.count is not None):
    print "Download and parse test traces of last", args.count, "build from", args.builder, "builder"
    downloadAndParseLastNFiles(getServerFileList(), args.count)
  else:
    print "Download and parse test traces of build", args.f, "-", args.t, "of", args.builder, "builder"
    downloadAndParseRangeFiles(args.f, args.t)
  totalParsed*=configDict[args.builder]
  printResult(args.v)

if __name__ == '__main__':
    main()


@echo off
SET originalDir=%cd%
SET rootDir=%~dp0..
SET lldbDir=%rootDir%\lldb
SET buildDir=%rootDir%\build
SET pythonExe=C:\Users\lldb_build\ll\prebuilts\python\x86
SET remoteDir=/data/local/tmp/lldb
SET toolchain=C:/Toolchains
SET port=5430
SET gstrace=gs://lldb_test_traces_asbuild
SET lockDir=c:\tmp\lock\lldbbuild.exclusivelock
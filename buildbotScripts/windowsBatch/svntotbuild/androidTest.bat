@echo off

FOR /F "tokens=1,2,3 delims=," %%A IN ("%*") DO (
    SET deviceId=%%A
    SET compiler=%%B
    SET arch=%%C
)
SET ndkApiList=21 19 18 17 16 15 14 13 12 9 8 5 4 3
SET LLDB_TEST_THREADS=8

call taskkill /f /im "adb.exe"
call adb -s %deviceId% shell getprop ro.build.fingerprint
call adb -s %deviceId% push %buildDir%\android-%arch%\bin\lldb-server %remoteDir%/ || goto :error
call adb -s %deviceId% shell chmod 755 %remoteDir%/lldb-server || goto :error
call adb forward --remove-all
call C:\Cygwin64\bin\screen -d -m adb -s %deviceId% shell TMPDIR=%remoteDir%/tmp %remoteDir%/lldb-server platform --listen 127.0.0.1:%port% --server || goto :error

REM Get sdklevel, then find the matching availabe ndk api level
for /f "delims=" %%a in ('adb -s %deviceId% shell getprop ro.build.version.sdk') do @set sdkLevel=%%a
call :getNdkApi %sdkLevel%
SET ndkapi=%errorlevel%

call %pythonHome%\python.exe %lldbDir%\test\dotest.py ^
--executable %buildDir%\bin\lldb.exe ^
-A %arch% -C %toolchain%/%arch%-%ndkapi%/bin/%compiler%.exe ^
-s c:\logs\logs-gcc-%arch% -u CXXFLAGS -u CFLAGS ^
--platform-name remote-android ^
--platform-url adb://%deviceId%:%port% ^
--platform-working-dir %remoteDir% ^
--env OS=Android -m

echo "Post Clean-Up"
SET PATH=%PATH%;C:\Cygwin64\bin
svn status %lldbDir%\test --no-ignore | grep "^[I?]" | cut -c 9- | sed 's:\\:/:g' | xargs rm
adb -s %deviceID% shell ps | grep lldb-server | awk "{print $2}" | xargs adb -s %deviceID% shell kill
adb -s %deviceID% shell rm -rf %remoteDir%/*

:error
exit /b %errorlevel%
cd %originalDir%

:getNdkApi
for %%a in (%ndkApiList%) do (
  if %%a LEQ %~1 (
    exit /b %%a
)
)

@echo off

FOR /F "tokens=1,2,3 delims=," %%A IN ("%*") DO (
    SET deviceId=%%A
    SET compiler=%%B
    SET arch=%%C
)
SET LLDB_TEST_THREADS=8

call taskkill /f /im "adb.exe"
call adb -s %deviceId% shell getprop ro.build.fingerprint
call adb -s %deviceId% push %buildDir%\android-%arch%\bin\lldb-server %remoteDir%/ || goto :error
call adb -s %deviceId% shell chmod 755 %remoteDir%/lldb-server || goto :error
call adb forward --remove-all
call screen -d -m adb -s %deviceId% shell TMPDIR=%remoteDir%/tmp %remoteDir%/lldb-server platform --listen 127.0.0.1:%port% --server || goto :error

call %pythonHome%\python.exe %lldbDir%\test\dotest.py ^
--executable %buildDir%\bin\lldb.exe ^
-A %arch% -C %compiler%.exe ^
-s logs-gcc-%arch% -u CXXFLAGS -u CFLAGS ^
--platform-name remote-android ^
--platform-url adb://%deviceId%:%port% ^
--platform-working-dir %remoteDir% ^
--env OS=Android -m

echo "Post Clean-Up"
svn status %lldbDir%\test --no-ignore | grep "^[I?]" | cut -c 9- | sed 's:\\:/:g' | xargs rm
adb -s %deviceID% shell ps | grep lldb-server | awk "{print $2}" | xargs adb -s %deviceID% shell kill
adb -s %deviceID% shell rm -rf %remoteDir%/*

:error
exit /b %errorlevel%
cd %originalDir%

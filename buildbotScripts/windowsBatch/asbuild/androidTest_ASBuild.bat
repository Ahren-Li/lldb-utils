@echo off

FOR /F "tokens=1,2,3 delims=," %%A IN ("%*") DO (
    SET deviceId=%%A
    SET compiler=%%B
    SET arch=%%C
)
SET LLDB_TEST_THREADS=8

call taskkill /f /im "adb.exe"
call adb -s %deviceId% shell getprop ro.build.fingerprint
call adb -s %deviceId% shell mkdir %remoteDir%
REM call adb -s %deviceId% push %buildDir%\%arch%\bin\lldb-server %remoteDir%/ || goto :error
call adb -s %deviceId% push %buildDir%\%arch%\lldb-server %remoteDir%/ || goto :error
call adb -s %deviceId% push %buildDir%\%arch%\lldb-server-3.8.0 %remoteDir%/ || goto :error
call adb -s %deviceId% shell chmod 755 %remoteDir%/lldb-server || goto :error
call adb forward --remove-all
call screen -d -m adb -s %deviceId% shell TMPDIR=%remoteDir%/tmp %remoteDir%/lldb-server platform --listen 127.0.0.1:%port% --server || goto :error

call %pythonHome%\python.exe %lldbDir%\test\dosep.py ^
--options ^"--executable %buildDir%\bin\lldb.exe ^
-A %arch% -C %compiler%.exe ^
-s logs-gcc-%arch% -u CXXFLAGS -u CFLAGS ^
--platform-name remote-android ^
--platform-url adb://%deviceId%:%port% ^
--platform-working-dir %remoteDir% ^
--env OS=Android -m^"

echo "Post Clean-Up"
adb -s %deviceID% shell ps | grep lldb-server | awk "{print $2}" | xargs adb -s %deviceID% shell kill
adb -s %deviceID% shell rm -rf %remoteDir%/*

:error
exit /b %errorlevel%
cd %originalDir%
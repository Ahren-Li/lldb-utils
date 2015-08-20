@echo off
if %1=="" (
    echo Please call this file with valid revision number
	exit /b 1
) else ( SET rev=%1)
SET gsbinaries=gs://lldb_binaries
cd ..
call gsutil cp %gsbinaries%/rev-%rev%.zip . || goto :error
call unzip -o rev-%rev%.zip || goto :error
call rm -f rev-%rev%.zip || goto :error

:error
exit /b %errorlevel%

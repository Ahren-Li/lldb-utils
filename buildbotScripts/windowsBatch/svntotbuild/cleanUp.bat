@echo off
call setEnv.bat || goto :error

rm -rf %buildDir%

:error
exit /b %errorlevel%
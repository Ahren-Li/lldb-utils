@echo off
call setEnv.bat || goto :error
cd %buildDir% || goto :error

ninja -j40

:error
exit /b %errorlevel%
cd %originalDir%
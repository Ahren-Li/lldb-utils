@echo off

call setEnv.bat || goto :error
call androidTest.bat %* ||goto :error

:error
exit /b %errorlevel%
cd %originalDir%
@echo off

call setEnv_ASBuild.bat || goto :error
call androidTest_ASBuild.bat %* ||goto :error

:error
exit /b %errorlevel%
cd %originalDir%
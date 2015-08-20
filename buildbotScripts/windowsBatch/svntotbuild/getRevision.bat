@echo off

call setEnv.bat || goto :error
svnversion %lldbDir% 

:error
exit /b %errorlevel%
cd %originalDir%
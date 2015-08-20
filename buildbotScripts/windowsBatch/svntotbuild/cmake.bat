@echo off
call setEnv.bat || goto :error

if not exist %buildDir% mkdir %buildDir%
cd %buildDir% || goto :error

cmake -G Ninja %llvmDir% ^
-DCMAKE_BUILD_TYPE=Release ^
-DPYTHON_LIBRARY=%pythonHome%\python27.lib ^
-DPYTHON_INCLUDE_DIR=%pythonHome%\Include ^
-DPYTHON_EXECUTABLE=%pythonHome%\python.exe ^
-DPYTHON_HOME=%pythonHome%

:error
exit /b %errorlevel%
cd %originalDir%
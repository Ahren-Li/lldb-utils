@echo off
setlocal enabledelayedexpansion
REM wait for 5 seconds, so the other builders will get the chance to acquire lock if any
ping 127.0.0.1 -n 6 > nul
call setEnv_ASBuild.bat
mkdir %lockDir%
if %errorlevel% == 0 (
  echo %1 make dir successfully, start build
  echo %1 > %lockDir%/lock.txt
  goto end
)

SET /p owner=<%lockDir%/lock.txt
echo Lock owner is %owner%

if %owner% == %1 (
  echo I am owner, start build
  goto end
)

echo I am not owner, wait for lock release ...

:while
ping 127.0.0.1 -n 4 > nul
mkdir %lockDir%
if %errorlevel% == 0 (
  echo %1 make dir successfully, start build
  echo %1 > %lockDir%/lock.txt
  goto end
) else (
  goto while
)

:end
exit /b 0
cd %originalDir%

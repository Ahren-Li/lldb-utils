@echo off
call setEnv.bat || goto :error
call cleanUp.bat
SET llvmsvn=http://llvm.org/svn/llvm-project/llvm/trunk
SET clangsvn=http://llvm.org/svn/llvm-project/cfe/trunk
SET lldbsvn=http://llvm.org/svn/llvm-project/lldb/trunk

if %1=="" (
    SET rev=HEAD
) else ( SET rev=%1)

call :svnFunc %llvmDir%, %llvmsvn%
call :svnFunc %clangDir%, %clangsvn%
call :svnFunc %lldbDir%, %lldbsvn%

:error
exit /b %errorlevel%

:svnFunc 
if exist "%~1\.svn" (
    call svn cleanup %~1
    call svn update --non-interactive --no-auth-cache --revision %rev% %~1 || goto :error
) else (
    call svn checkout --non-interactive --no-auth-cache --revision %rev% %~2@%rev% %~1 || goto :error
)

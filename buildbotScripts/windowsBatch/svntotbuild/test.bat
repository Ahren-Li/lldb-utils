@echo off

call setEnv.bat || goto :error
SET PATH=C:\Windows\system32;C:\Program Files (x86)\LLVM\bin;C:\Users\lldb_build\ll\prebuilts\python\x86;C:\Android\sdk\platform-tools;C:\Tools\gnuwin32\bin;C:\Tools\cygwin;
call androidTest.bat %* ||goto :error

:error
exit /b %errorlevel%
cd %originalDir%

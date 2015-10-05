@echo off

SET gstrace=gs://lldb_test_traces_asbuild

call zip -r build-%1 logs-* || goto :error
call gsutil cp build-%1.zip %gstrace%/%2/ || goto :error
call rm build-%1.zip
call rm -rf logs-*

set /a oldNum=(%1-500)
REM remove old test trace of build $oldNum
gsutil rm %gstrace%/%2/build-%oldNum%.zip || true
rm %rootDir%\*.zip || true

:error
exit /b %errorlevel%
cd %originalDir%


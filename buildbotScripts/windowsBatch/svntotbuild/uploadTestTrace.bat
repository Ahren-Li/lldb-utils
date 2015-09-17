@echo off

SET gstrace=gs://lldb_test_traces
call zip -r build-%1 logs-* || goto :error
call gsutil cp build-%1.zip %gstrace%/%2/ || goto :error
call rm build-%1.zip
call rm -rf c:\logs\logs-*

set /a oldNum=(%1-500)
echo Remove old test trace of build %oldNum%
call gsutil rm %gstrace%/%2/build-%oldNum%.zip || true

:error
exit /b %errorlevel%

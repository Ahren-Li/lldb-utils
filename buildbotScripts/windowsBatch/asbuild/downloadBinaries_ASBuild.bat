
SET gs_asbin_linux=gs://lldb_asbuild_binaries/builds/git_studio-1.4-dev-linux-lldb_linux
SET gs_asbin_windows=gs://lldb_asbuild_binaries/builds/git_studio-1.4-dev-windows-lldb_windows
cd ..
call gsutil cp -r %gs_asbin_windows%/%1/** . || goto :error
call gsutil cp -r %gs_asbin_linux%/%1/** . || goto :error
call unzip -o lldb-tests-* -d lldb/ || goto :error
call unzip -o lldb-android-* -d build/ || goto :error
call unzip -o lldb-windows-* -d build/ || goto :error
call rm -f *.zip || goto :error

:error
exit /b %errorlevel%
cd %originalDir%

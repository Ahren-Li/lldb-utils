set(OS windows)

include(${CMAKE_CURRENT_LIST_DIR}/host.cmake)

set(LLDB_RELOCATABLE_PYTHON ON CACHE BOOL "Relocatable python")
set(PYTHON_HOME "${PREBUILTS}/python/windows-x86/x64" CACHE PATH "Python home")
set(PYTHON_EXECUTABLE "${PREBUILTS}/python/windows-x86/x64/python.exe" CACHE PATH "Python EXE")
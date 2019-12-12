set(REPO_ROOT ${CMAKE_CURRENT_LIST_DIR}/../../..)
set(PREBUILTS ${REPO_ROOT}/prebuilts)

# Configure cmake
set(CMAKE_GENERATOR Ninja CACHE STRING "CMake generator")
set(CMAKE_MAKE_PROGRAM "${PREBUILTS}/ninja/${OS}-x86/ninja${CMAKE_EXECUTABLE_SUFFIX}"
  CACHE STRING "Ninja program")
set(CMAKE_BUILD_TYPE Release CACHE STRING "Release, MinSizeRel, RelWithDebInfo, Debug")
set(CMAKE_INSTALL_PREFIX "" CACHE STRING "Installation prefix")
set(CMAKE_TOOLCHAIN_FILE "${CMAKE_CURRENT_LIST_DIR}/${OS}.toolchain.cmake"
  CACHE STRING "Toolchain file")

# Configure LLVM
set(LLVM_TARGETS_TO_BUILD "X86;ARM;AArch64;Mips" CACHE STRING "X86, ARM, AArch64, Mips")
set(LLVM_EXTERNAL_CLANG_SOURCE_DIR "${REPO_ROOT}/external/llvm-project/clang"
  CACHE STRING "Clang source path")
set(LLVM_EXTERNAL_LLDB_SOURCE_DIR "${REPO_ROOT}/external/llvm-project/lldb"
  CACHE STRING "LLDB source path")

set(LLDB_DISABLE_CURSES ON CACHE BOOL "Disable curses support")

set(SWIG_DIR "${PREBUILTS}/swig/${OS}-x86" CACHE PATH "Swig directory")
set(SWIG_EXECUTABLE "${SWIG_DIR}/bin/swig${CMAKE_EXECUTABLE_SUFFIX}"
  CACHE STRING "Swig executable")

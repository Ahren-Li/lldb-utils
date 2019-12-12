set(REPO_ROOT ${CMAKE_CURRENT_LIST_DIR}/../../..)
set(PREBUILTS ${REPO_ROOT}/prebuilts)
set(TOOLCHAIN "${PREBUILTS}/gcc/linux-x86/host/x86_64-linux-glibc2.15-4.8")

set(CMAKE_C_COMPILER "${PREBUILTS}/clang/host/linux-x86/clang-4691093/bin/clang")
set(CMAKE_CXX_COMPILER "${PREBUILTS}/clang/host/linux-x86/clang-4691093/bin/clang++")
set(CMAKE_SYSROOT "${TOOLCHAIN}/sysroot")
set(CMAKE_CXX_STANDARD_INCLUDE_DIRECTORIES
  "${TOOLCHAIN}/x86_64-linux/include/c++/4.8"
  "${TOOLCHAIN}/x86_64-linux/include/c++/4.8/x86_64-linux"
  "${PREBUILTS}/libedit/linux-x86/include"
  )

set(CMAKE_C_STANDARD_LIBRARIES_INIT
"-L${TOOLCHAIN}/lib/gcc/x86_64-linux/4.8 \
-L${TOOLCHAIN}/x86_64-linux/lib64 \
-L${PREBUILTS}/libedit/linux-x86/lib \
-B${TOOLCHAIN}/bin/x86_64-linux- \
-B${TOOLCHAIN}/lib/gcc/x86_64-linux/4.8/")
set(CMAKE_CXX_STANDARD_LIBRARIES_INIT "${CMAKE_C_STANDARD_LIBRARIES_INIT}")
set(CMAKE_C_COMPILER_TARGET x86_64-unknown-linux)
set(CMAKE_CXX_COMPILER_TARGET x86_64-unknown-linux)
set(CMAKE_C_COMPILER_EXTERNAL_TOOLCHAIN ${TOOLCHAIN})
set(CMAKE_CXX_COMPILER_EXTERNAL_TOOLCHAIN ${TOOLCHAIN})
set(_CMAKE_TOOLCHAIN_PREFIX "${TOOLCHAIN}/bin/x86_64-linux-")

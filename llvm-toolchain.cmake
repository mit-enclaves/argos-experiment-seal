set(CMAKE_SYSTEM_NAME Linux)
set(CMAKE_SYSTEM_VERSION 1)
set(CMAKE_SYSROOT /home/drean/tyche-experiment-seal/toolchain-root)

set(CMAKE_C_COMPILER clang)
set(CMAKE_CXX_COMPILER clang++)

# Set the include paths
set(CMAKE_C_FLAGS "-O0 -g3 -ggdb3 -nostdinc -nodefaultlibs --sysroot=${CMAKE_SYSROOT} -isystem ${CMAKE_SYSROOT}/include -isystem /usr/include -isystem /usr/include/x86_64-linux-gnu -isystem /usr/include/linux -Wl,-z,norelro")
set(CMAKE_CXX_FLAGS "${CMAKE_C_FLAGS} -nostdinc++")
set(CMAKE_EXE_LINKER_FLAGS "-static -lc -z norelro -nostdlib --sysroot=${CMAKE_SYSROOT} -L${CMAKE_SYSROOT}/lib")

set(CMAKE_FIND_ROOT_PATH ${CMAKE_SYSROOT})
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)

# Prevent CMake from adding the system default library paths
set(CMAKE_IGNORE_PATH /usr/lib /usr/local/lib /lib)

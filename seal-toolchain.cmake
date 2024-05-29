set(CMAKE_SYSTEM_NAME Linux)
set(CMAKE_SYSTEM_VERSION 1)
set(CMAKE_SYSROOT /home/drean/tyche-experiment-seal/toolchain-root)

set(CMAKE_C_COMPILER clang)
set(CMAKE_CXX_COMPILER clang++)

# Set the include paths
set(CMAKE_C_FLAGS "-nostdinc -nodefaultlibs --sysroot=${CMAKE_SYSROOT} -isystem ${CMAKE_SYSROOT}/include/c++/v1 -isystem /usr/lib/llvm-14/lib/clang/14.0.0/include -isystem ${CMAKE_SYSROOT}/include ")
set(CMAKE_CXX_FLAGS "${CMAKE_C_FLAGS} -nostdinc++")
set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_SYSROOT}/lib/crt1.o ${CMAKE_SYSROOT}/lib/crti.o ${CMAKE_SYSROOT}/lib/crtn.o -nostdlib -static --sysroot=${CMAKE_SYSROOT} -L${CMAKE_SYSROOT}/lib -lc++ -lc++abi -lm -lpthread -ldl -lutil -lrt -lc")

#set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} ${CMAKE_SYSROOT}/lib/crt1.o ${CMAKE_SYSROOT}/lib/crti.o ${CMAKE_SYSROOT}/lib/crtn.o")

set(CMAKE_FIND_ROOT_PATH ${CMAKE_SYSROOT})
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)

# Prevent CMake from adding the system default library paths
set(CMAKE_IGNORE_PATH /usr/lib /usr/local/lib /lib)

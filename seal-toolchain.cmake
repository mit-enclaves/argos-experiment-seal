set(CMAKE_SYSTEM_NAME Linux)
set(CMAKE_SYSTEM_VERSION 1)

get_filename_component(TOOLCHAIN_DIR "${CMAKE_CURRENT_LIST_FILE}" PATH)
set(TOOLCHAIN_ROOT "${TOOLCHAIN_DIR}/toolchain-root")

set(CMAKE_SYSROOT ${TOOLCHAIN_ROOT})

set(CMAKE_C_COMPILER clang)
set(CMAKE_CXX_COMPILER clang++)

# Set the include paths
set(CMAKE_C_FLAGS "-O0 -g3 -ggdb3 -nodefaultlibs --sysroot=${CMAKE_SYSROOT} -isystem ${CMAKE_SYSROOT}/include/c++/v1 -isystem ${CMAKE_SYSROOT}/include")
set(CMAKE_CXX_FLAGS "${CMAKE_C_FLAGS}")
set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_SYSROOT}/lib/crt1.o ${CMAKE_SYSROOT}/lib/crti.o -nostdlib -static -z norelro --sysroot=${CMAKE_SYSROOT} -L${CMAKE_SYSROOT}/lib -lc++ -lc++abi -lm -lpthread -ldl -lutil -lrt -lc ${CMAKE_SYSROOT}/lib/crtn.o") # -lc++ -lc++abi -lm -lpthread -ldl -lutil -lrt -lc")

#set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} ${CMAKE_SYSROOT}/lib/crt1.o ${CMAKE_SYSROOT}/lib/crti.o ${CMAKE_SYSROOT}/lib/crtn.o")

set(CMAKE_FIND_ROOT_PATH ${CMAKE_SYSROOT})
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)

# Prevent CMake from adding the system default library paths
set(CMAKE_IGNORE_PATH /usr/lib /usr/local/lib /lib)

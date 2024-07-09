# Path to the musl-gcc

CUR_DIR := justfile_directory()

ROOT := justfile_directory() + "/toolchain-root" 

MUSL_GCC := "{{ROOT}}/bin/musl-gcc"

LLVM_DIR := justfile_directory() + "/llvm-project"
LIBCXX_BUILD := justfile_directory() + "/llvm-project/build-libcxx"
CLANG_BUILD := justfile_directory() + "/llvm-project/build-clang"
SEAL_BUILD := justfile_directory() + "/SEAL/build"

clean:
    make -C tyche-musl clean

build-clang:
  cd llvm-project && cmake -G Ninja -S llvm -B {{CLANG_BUILD}} -DLLVM_ENABLE_PROJECTS="clang" -DCMAKE_INSTALL_PREFIX="{{ROOT}}"
  ninja -C {{CLANG_BUILD}}

build-musl:
  cd tyche-musl && ./configure --prefix={{ROOT}} --exec-prefix={{ROOT}} --disable-shared --enable-debug
  make -C tyche-musl/ -j `nproc` CFLAGS="-static -g3 -ggdb3 -O0 -Wl,-z,norelro"
  make -C tyche-musl/ install

build-libcxx:
  cd llvm-project && cmake -G Ninja -S runtimes -B {{LIBCXX_BUILD}} -DLLVM_ENABLE_RUNTIMES="libcxx;libcxxabi;libunwind" -DCMAKE_TOOLCHAIN_FILE="{{CUR_DIR}}/llvm-toolchain.cmake" -DCMAKE_INSTALL_PREFIX="{{ROOT}}" -DLIBCXXABI_USE_LLVM_UNWINDER=ON -DLIBCXX_HAS_MUSL_LIBC=ON -DLIBCXX_ENABLE_LOCALIZATION=ON -DLIBCXX_ENABLE_SHARED=OFF -DLIBCXX_ENABLE_EXPERIMENTAL_LIBRARY=OFF -DLIBCXXABI_ENABLE_STATIC_UNWINDER=ON -DLIBCXXABI_ENABLE_SHARED=OFF -DLIBUNWIND_ENABLE_SHARED=OFF
  ninja -C {{LIBCXX_BUILD}} -j `nproc` cxx cxxabi unwind install

build-seal:
  cmake -S SEAL -B {{SEAL_BUILD}} -DCMAKE_TOOLCHAIN_FILE="{{CUR_DIR}}/seal-toolchain.cmake" -DCMAKE_INSTALL_PREFIX={{ROOT}} -DSEAL_USE_INTRIN=OFF -DSEAL_BUILD_EXAMPLES=ON
  cmake --build {{SEAL_BUILD}} --parallel
  cmake --install {{SEAL_BUILD}}

objdump-seal:
  objdump -x {{SEAL_BUILD}}/bin/sealexamples > objdump-seal.out
   
refresh:
  @rm -rf {{ROOT}}
  @rm -rf {{CLANG_BUILD}}
  @rm -rf {{LIBCXX_BUILD}}
  @rm -rf {{SEAL_BUILD}}
  @just clean
  @just build-musl
  @just build-libcxx
  @just build-seal

ref:
  @rm -rf {{LIBCXX_BUILD}}
  @just build-libcxx

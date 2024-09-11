# Path to the musl-gcc

CUR_DIR := justfile_directory()

ROOT := justfile_directory() + "/toolchain-root" 

MUSL_GCC := "{{ROOT}}/bin/musl-gcc"

LLVM_DIR := justfile_directory() + "/llvm-project"
LIBCXX_BUILD := justfile_directory() + "/llvm-project/build-libcxx"
SEAL_BUILD := justfile_directory() + "/SEAL/build"

setup-musl:
  cd tyche-musl && ./configure --prefix={{ROOT}} --exec-prefix={{ROOT}} --disable-shared --enable-debug

build-musl:
  make -C tyche-musl/ -j `nproc` CFLAGS="-static -g3 -ggdb3 -O0 -Wl,-z,norelro"
  make -C tyche-musl/ install

clean-musl:
  make -C tyche-musl clean

refresh-musl:
  @just clean-musl
  @just setup-musl
  @just build-musl

setup-libcxx:
  cd llvm-project && cmake -G Ninja -S runtimes -B {{LIBCXX_BUILD}} -DLLVM_ENABLE_RUNTIMES="libcxx;libcxxabi;libunwind" -DCMAKE_TOOLCHAIN_FILE="{{CUR_DIR}}/llvm-toolchain.cmake" -DCMAKE_INSTALL_PREFIX="{{ROOT}}" -DLIBCXXABI_USE_LLVM_UNWINDER=ON -DLIBCXX_HAS_MUSL_LIBC=ON -DLIBCXX_ENABLE_LOCALIZATION=ON -DLIBCXX_ENABLE_SHARED=OFF -DLIBCXX_ENABLE_EXPERIMENTAL_LIBRARY=OFF -DLIBCXXABI_ENABLE_STATIC_UNWINDER=ON -DLIBCXXABI_ENABLE_SHARED=OFF -DLIBUNWIND_ENABLE_SHARED=OFF -DLIBUNWIND_ENABLE_STATIC=ON -DLIBUNWIND_IS_BAREMETAL=ON 

build-libcxx:
  ninja -C {{LIBCXX_BUILD}} -j `nproc` cxx cxxabi unwind install

clean-libcxx:
  @rm -rf {{LIBCXX_BUILD}}

refresh-libcxx:
  @just clean-libcxx
  @just setup-libcxx
  @just build-libcxx

setup-seal:
  cmake -S SEAL -B {{SEAL_BUILD}} -DCMAKE_TOOLCHAIN_FILE="{{CUR_DIR}}/seal-toolchain.cmake" -DCMAKE_INSTALL_PREFIX={{ROOT}} -DSEAL_USE_INTRIN=OFF -DSEAL_BUILD_EXAMPLES=ON

build-seal:
  cmake --build {{SEAL_BUILD}} --parallel
  cmake --install {{SEAL_BUILD}}

clean-seal:
  @rm -rf {{SEAL_BUILD}}

refresh-seal:
  @just clean-seal
  @just setup-seal
  @just build-seal

objdump-seal:
  objdump -x {{SEAL_BUILD}}/bin/sealexamples > objdump-seal.out

all:
  @just setup-musl
  @just build-musl
  @just setup-libcxx
  @just build-libcxx
  @just setup-seal
  @just build-seal

build:
  @just build-musl
  @just build-libcxx
  @just build-seal

clean:
  @rm -rf {{ROOT}}
  @just clean-musl
  @just clean-libcxx
  @just clean-seal
   
refresh:
  @rm -rf {{ROOT}}
  @just refresh-musl
  @just refresh-libcxx
  @just refresh-seal

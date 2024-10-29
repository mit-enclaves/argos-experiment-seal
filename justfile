# Path to the musl-gcc

CUR_DIR := justfile_directory()

ROOT := justfile_directory() + "/toolchain-root" 

MUSL_GCC := "{{ROOT}}/bin/musl-gcc"

MUSL_DIR := justfile_directory() + "/tyche-musl"
LLVM_DIR := justfile_directory() + "/llvm-project"
LIBCXX_BUILD := justfile_directory() + "/llvm-project/build-libcxx"
SEAL_BUILD := justfile_directory() + "/SEAL/build"
SEAL_BENCH_BUILD := justfile_directory() + "/SEAL/native/bench/build"
SEAL_PIR_BUILD := justfile_directory() + "/SealPIR/build"

setup-musl:
  cd {{MUSL_DIR}} && ./configure --prefix={{ROOT}} --exec-prefix={{ROOT}} --disable-shared --enable-debug

build-musl:
  make -C {{MUSL_DIR}}/ -j `nproc` CFLAGS="-static -O3 -Wl,-z,norelro"
  make -C {{MUSL_DIR}}/ install

build-musl-no-tyche:
  make -C {{MUSL_DIR}}/ -j `nproc` CFLAGS="-static -D RUN_WITHOUT_TYCHE -O3 -Wl,-z,norelro"
  make -C {{MUSL_DIR}}/ install

clean-musl:
  make -C {{MUSL_DIR}} clean

refresh-musl:
  @just clean-musl
  @just setup-musl
  @just build-musl

refresh-musl-no-tyche:
  @just clean-musl
  @just setup-musl
  @just build-musl-no-tyche

setup-libcxx:
  cd llvm-project && cmake -G Ninja -S runtimes -B {{LIBCXX_BUILD}} \
  -DLLVM_ENABLE_RUNTIMES="libcxx;libcxxabi;libunwind;" \
  -DCMAKE_TOOLCHAIN_FILE="{{CUR_DIR}}/llvm-toolchain.cmake" \
  -DCMAKE_INSTALL_PREFIX="{{ROOT}}" \
  -DLIBCXXABI_USE_LLVM_UNWINDER=ON \
  -DLIBCXX_HAS_MUSL_LIBC=ON \
  -DLIBCXX_ENABLE_LOCALIZATION=ON \
  -DLIBCXX_ENABLE_SHARED=OFF \
  -DLIBCXX_ENABLE_EXPERIMENTAL_LIBRARY=OFF \
  -DLIBCXXABI_ENABLE_STATIC_UNWINDER=ON \
  -DLIBCXXABI_ENABLE_SHARED=OFF \
  -DLIBUNWIND_ENABLE_SHARED=OFF \
  -DLIBUNWIND_ENABLE_STATIC=ON \
  -DLIBUNWIND_IS_BAREMETAL=ON \

build-libcxx:
  ninja -C {{LIBCXX_BUILD}} -j `nproc` cxx cxxabi unwind install

clean-libcxx:
  @rm -rf {{LIBCXX_BUILD}}

refresh-libcxx:
  @just clean-libcxx
  @just setup-libcxx
  @just build-libcxx

setup-seal:
  cmake -S SEAL -B {{SEAL_BUILD}} -DCMAKE_TOOLCHAIN_FILE="{{CUR_DIR}}/seal-toolchain.cmake" -DCMAKE_INSTALL_PREFIX={{ROOT}} -DSEAL_USE_INTRIN=ON -DSEAL_USE_INTEL_HEXL=ON -DSEAL_BUILD_EXAMPLES=ON

build-seal:
  cmake --build {{SEAL_BUILD}} --parallel $(nproc)
  cmake --install {{SEAL_BUILD}}

build-seal-bench:
  cmake -S SEAL/native/bench -B {{SEAL_BENCH_BUILD}} -DCMAKE_TOOLCHAIN_FILE="{{CUR_DIR}}/seal-toolchain.cmake" -DCMAKE_INSTALL_PREFIX={{ROOT}} -DSEAL_ROOT={{ROOT}} -DCMAKE_THREAD_LIBS_INIT="-lpthread" -DHAVE_THREAD_SAFETY_ATTRIBUTES=OFF -DHAVE_STD_REGEX=ON
  cmake --build {{SEAL_BENCH_BUILD}} --parallel $(nproc)


build-seal-pir:
  cmake -S SealPIR -B {{SEAL_PIR_BUILD}} -DCMAKE_TOOLCHAIN_FILE="{{CUR_DIR}}/seal-toolchain.cmake" -DCMAKE_INSTALL_PREFIX={{ROOT}} -DSEAL_ROOT={{ROOT}} -DCMAKE_THREAD_LIBS_INIT="-lpthread"
  make -C {{SEAL_PIR_BUILD}} -j `nproc`

clean-seal:
  @rm -rf {{SEAL_BUILD}}

clean-seal-bench:
  @rm -rf {{SEAL_BENCH_BUILD}}

clean-seal-pir:
  @rm -rf {{SEAL_PIR_BUILD}}

refresh-seal:
  @just clean-seal
  @just setup-seal
  @just build-seal

refresh-seal-bench:
  @just clean-seal-bench
  @just build-seal-bench

refresh-seal-pir:
  @just clean-seal-pir
  @just build-seal-pir

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
  @just refresh-seal-pir

refresh-no-tyche:
  @rm -rf {{ROOT}}
  @just refresh-musl-no-tyche
  @just refresh-libcxx
  @just refresh-seal

refresh-light:
  @touch {{MUSL_DIR}}/src/internal/tyche.c
  @touch {{MUSL_DIR}}/src/internal/tyche_alloc.c
  @touch {{SEAL_BUILD}}/native/examples/CMakeFiles/sealexamples.dir/examples.cpp.o
  @touch {{SEAL_BENCH_BUILD}}/CMakeFiles/sealbench.dir/bench.cpp.o
  @touch {{SEAL_PIR_BUILD}}/src/CMakeFiles/main.dir/main.cpp.o
  @just build-musl
  @just build-seal
  @just build-seal-bench
  @just build-seal-pir

refresh-no-tyche-light:
  @touch {{MUSL_DIR}}/src/internal/tyche.c
  @touch {{MUSL_DIR}}/src/internal/tyche_alloc.c
  @touch {{SEAL_BUILD}}/native/examples/CMakeFiles/sealexamples.dir/examples.cpp.o
  @touch {{SEAL_BENCH_BUILD}}/CMakeFiles/sealbench.dir/bench.cpp.o
  @touch {{SEAL_PIR_BUILD}}/src/CMakeFiles/main.dir/main.cpp.o
  @just build-musl-no-tyche
  @just build-seal
  @just build-seal-bench
  @just build-seal-pir
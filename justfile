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
SEAL_APSI_BUILD := justfile_directory() + "/APSI/build"
KUKU_BUILD := justfile_directory() + "/Kuku/build"
FLATBUFFERS_BUILD := justfile_directory() + "/flatbuffers/build"
JSONCPP_BUILD := justfile_directory() + "/jsoncpp/build"

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
  cmake -S SEAL -B {{SEAL_BUILD}} -DCMAKE_TOOLCHAIN_FILE="{{CUR_DIR}}/seal-toolchain.cmake" -DCMAKE_INSTALL_PREFIX={{ROOT}} -DSEAL_USE_INTRIN=ON -DSEAL_USE_INTEL_HEXL=ON -DSEAL_BUILD_EXAMPLES=ON -DSEAL_THROW_ON_TRANSPARENT_CIPHERTEXT=OFF

build-seal:
  cmake --build {{SEAL_BUILD}} --parallel $(nproc)
  cmake --install {{SEAL_BUILD}}

build-seal-bench:
  cmake -S SEAL/native/bench -B {{SEAL_BENCH_BUILD}} -DCMAKE_TOOLCHAIN_FILE="{{CUR_DIR}}/seal-toolchain.cmake" -DCMAKE_INSTALL_PREFIX={{ROOT}} -DSEAL_ROOT={{ROOT}} -DCMAKE_THREAD_LIBS_INIT="-lpthread" -DHAVE_THREAD_SAFETY_ATTRIBUTES=OFF -DHAVE_STD_REGEX=ON
  cmake --build {{SEAL_BENCH_BUILD}} --parallel $(nproc)


build-seal-pir:
  cmake -S SealPIR -B {{SEAL_PIR_BUILD}} -DCMAKE_TOOLCHAIN_FILE="{{CUR_DIR}}/seal-toolchain.cmake" -DCMAKE_INSTALL_PREFIX={{ROOT}} -DSEAL_ROOT={{ROOT}} -DCMAKE_THREAD_LIBS_INIT="-lpthread"
  make -C {{SEAL_PIR_BUILD}} -j `nproc`

build-kuku:
  cmake -S Kuku -B {{KUKU_BUILD}} -DCMAKE_TOOLCHAIN_FILE="{{CUR_DIR}}/seal-toolchain.cmake" -DCMAKE_INSTALL_PREFIX={{ROOT}} -DSEAL_ROOT={{ROOT}} -DCMAKE_THREAD_LIBS_INIT="-lpthread"
  cmake --build {{KUKU_BUILD}} --parallel $(nproc)
  cmake --install {{KUKU_BUILD}}

build-flatbuffers:
  cmake -S flatbuffers -B {{FLATBUFFERS_BUILD}} -G "Unix Makefiles" -DCMAKE_BUILD_TYPE=Release
  make -C {{FLATBUFFERS_BUILD}} -j `nproc`
  sudo make -C {{FLATBUFFERS_BUILD}} install

build-jsoncpp:
  cmake -S jsoncpp -B {{JSONCPP_BUILD}} \
    -DCMAKE_TOOLCHAIN_FILE="{{CUR_DIR}}/seal-toolchain.cmake" \
    -DCMAKE_INSTALL_PREFIX={{ROOT}} \
    -DBUILD_SHARED_LIBS=OFF \
    -DBUILD_STATIC_LIBS=ON \
    -DJSONCPP_WITH_TESTS=OFF \
    -DJSONCPP_WITH_POST_BUILD_UNITTEST=OFF \
    -DJSONCPP_WITH_EXAMPLE=OFF
  cmake --build {{JSONCPP_BUILD}} --parallel $(nproc)
  cmake --install {{JSONCPP_BUILD}}

build-seal-apsi:
  @just build-flatbuffers
  @just build-kuku
  @just build-jsoncpp
  cmake -S APSI -B {{SEAL_APSI_BUILD}} \
    -DCMAKE_TOOLCHAIN_FILE="{{CUR_DIR}}/seal-toolchain.cmake" \
    -DCMAKE_INSTALL_PREFIX={{ROOT}} \
    -DSEAL_ROOT={{ROOT}} \
    -DCMAKE_THREAD_LIBS_INIT="-lpthread" \
    -DAPSI_BUILD_TESTS=ON \
    -DCMAKE_BUILD_TYPE=Release \
    -DAPSI_USE_LOG4CPLUS=OFF \
    -DAPSI_USE_ZMQ=OFF
  make -C {{SEAL_APSI_BUILD}} -j `nproc`

clean-seal:
  @rm -rf {{SEAL_BUILD}}

clean-seal-bench:
  @rm -rf {{SEAL_BENCH_BUILD}}

clean-seal-pir:
  @rm -rf {{SEAL_PIR_BUILD}}

clean-kuku:
  @rm -rf {{KUKU_BUILD}}

clean-jsoncpp:
  @rm -rf {{JSONCPP_BUILD}}

clean-flatbuffers:
  @rm -rf {{FLATBUFFERS_BUILD}}

clean-seal-apsi:
  @just clean-kuku
  @just clean-jsoncpp
  @just clean-flatbuffers
  @rm -rf {{SEAL_APSI_BUILD}}

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

refresh-seal-apsi:
  @just clean-seal-apsi
  @just build-seal-apsi

objdump-seal:
  objdump -x {{SEAL_BUILD}}/bin/sealexamples > objdump-seal.out

all:
  @just setup-musl
  @just build-musl
  @just setup-libcxx
  @just build-libcxx
  @just setup-seal
  @just build-seal
  @just build-seal-bench
  @just build-seal-pir
  @just build-seal-apsi

build:
  @just build-musl
  @just build-libcxx
  @just build-seal
  @just build-seal-bench
  @just build-seal-pir
  @just build-seal-apsi

clean:
  @rm -rf {{ROOT}}
  @just clean-musl
  @just clean-libcxx
  @just clean-seal
  @just clean-seal-bench
  @just clean-seal-pir
  @just clean-seal-apsi
   
refresh:
  @rm -rf {{ROOT}}
  @just refresh-musl
  @just refresh-libcxx
  @just refresh-seal
  @just refresh-seal-bench
  @just refresh-seal-pir
  @just refresh-seal-apsi

refresh-no-tyche:
  @rm -rf {{ROOT}}
  @just refresh-musl-no-tyche
  @just refresh-libcxx
  @just refresh-seal
  @just refresh-seal-bench
  @just refresh-seal-pir
  @just refresh-seal-apsi
  
refresh-light:
  @touch {{MUSL_DIR}}/src/internal/tyche.c
  @touch {{MUSL_DIR}}/src/internal/tyche_alloc.c
  @touch {{SEAL_BUILD}}/native/examples/CMakeFiles/sealexamples.dir/examples.cpp.o
  @touch {{SEAL_BENCH_BUILD}}/CMakeFiles/sealbench.dir/bench.cpp.o
  @touch {{SEAL_PIR_BUILD}}/src/CMakeFiles/main.dir/main.cpp.o
  @touch {{SEAL_APSI_BUILD}}/CMakeFiles/integration_tests.dir/tests/integration/src/integration_tests_runner.cpp.o
  @just build-musl
  @just build-seal
  @just build-seal-bench
  @just build-seal-pir
  @just build-seal-apsi

refresh-no-tyche-light:
  @touch {{MUSL_DIR}}/src/internal/tyche.c
  @touch {{MUSL_DIR}}/src/internal/tyche_alloc.c
  @touch {{SEAL_BUILD}}/native/examples/CMakeFiles/sealexamples.dir/examples.cpp.o
  @touch {{SEAL_BENCH_BUILD}}/CMakeFiles/sealbench.dir/bench.cpp.o
  @touch {{SEAL_PIR_BUILD}}/src/CMakeFiles/main.dir/main.cpp.o
  @touch {{SEAL_APSI_BUILD}}/CMakeFiles/integration_tests.dir/tests/integration/src/integration_tests_runner.cpp.o
  @just build-musl-no-tyche
  @just build-seal
  @just build-seal-bench
  @just build-seal-pir
  @just build-seal-apsi

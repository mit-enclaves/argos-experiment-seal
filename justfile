# Path to the musl-gcc

MUSL_GCC := justfile_directory() + "/musl-build/bin/musl-gcc"

MUSL_INSTALL := justfile_directory() + "/musl-build" 

LIBCXX_INSTALL := justfile_directory() + "/llvm-project/build"

clean:
    make -C tyche-musl clean

build-musl:
  cd tyche-musl && ./configure --prefix={{MUSL_INSTALL}} --exec-prefix={{MUSL_INSTALL}} --disable-shared --enable-debug
  make -C tyche-musl/ -j `nproc`  CFLAGS="-static -Os -Wl,-z,norelro"
  make -C tyche-musl/ install

build-libcxx:
  cd llvm-project && cmake -G Ninja -S runtimes -B {{LIBCXX_INSTALL}} -DLLVM_ENABLE_RUNTIMES="libcxx;libcxxabi;libunwind" -DCMAKE_C_COMPILER=clang -DCMAKE_CXX_COMPILER=clang++ -DLIBCXXABI_USE_LLVM_UNWINDER=ON -DLIBCXX_HAS_MUSL_LIBC=ON -DLIBCXX_ENABLE_LOCALIZATION=OFF -DLIBCXX_ENABLE_SHARED=OFF -DLIBCXX_ENABLE_EXPERIMENTAL_LIBRARY=OFF -DLIBCXXABI_ENABLE_STATIC_UNWINDER=ON -DLIBCXXABI_ENABLE_SHARED=OFF -DLIBUNWIND_ENABLE_SHARED=OFF
  ninja -C {{LIBCXX_INSTALL}} cxx cxxabi unwind

refresh:
  @rm -rf {{MUSL_INSTALL}}
  @rm -rf {{LIBCXX_INSTALL}}
  @just clean
  @just build-musl
  @just build-libcxx

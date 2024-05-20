# Path to the musl-gcc

MUSL_BUILD := justfile_directory() + "/musl-build" 

MUSL_GCC := "{{MUSL_BUILD}}/bin/musl-gcc"

LIBCXX_BUILD := justfile_directory() + "/llvm-project/build"

clean:
    make -C tyche-musl clean

build-musl:
  cd tyche-musl && ./configure --prefix={{MUSL_BUILD}} --exec-prefix={{MUSL_BUILD}} --disable-shared --enable-debug
  make -C tyche-musl/ -j `nproc` CFLAGS="-static -Os -Wl,-z,norelro"
  make -C tyche-musl/ install

CFLAGS := "-nodefaultlibs --sysroot {{MUSL_BUILD}} -isystem {{MUSL_BUILD}}/include"
LDFLAGS := "-nostdlib --sysroot {{MUSL_BUILD}} -L {{MUSL_BUILD}}/lib -lc"

build-libcxx:
  export CFLAGS="{{CFLAGS}}"
  export LDFLAGS="{{LDFLAGS}}"
  cd llvm-project && cmake -G Ninja -S runtimes -B {{LIBCXX_BUILD}} -DLLVM_ENABLE_RUNTIMES="libcxx;libcxxabi;libunwind" -DCMAKE_C_COMPILER=clang -DCMAKE_CXX_COMPILER=clang++ -DLIBCXXABI_USE_LLVM_UNWINDER=ON -DLIBCXX_HAS_MUSL_LIBC=ON -DLIBCXX_ENABLE_LOCALIZATION=OFF -DLIBCXX_ENABLE_SHARED=OFF -DLIBCXX_ENABLE_EXPERIMENTAL_LIBRARY=OFF -DLIBCXXABI_ENABLE_STATIC_UNWINDER=ON -DLIBCXXABI_ENABLE_SHARED=OFF -DLIBUNWIND_ENABLE_SHARED=OFF
  ninja -C {{LIBCXX_BUILD}} cxx cxxabi unwind 

refresh:
  @rm -rf {{MUSL_BUILD}}
  @rm -rf {{LIBCXX_BUILD}}
  @just clean
  @just build-musl
  @just build-libcxx

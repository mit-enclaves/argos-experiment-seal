# Path to the musl-gcc

MUSL_GCC := justfile_directory() + "/musl-build/bin/musl-gcc"

MUSL_INSTALL := justfile_directory() + "/musl-build" 

LIBCXX_INSTALL := justfile_directory() + "/libcxx-build"

clean:
    make -C tyche-musl clean
    make -C tyche-redis clean
    make -C tyche-redis distclean

build-musl:
  cd tyche-musl && ./configure --prefix={{MUSL_INSTALL}} --exec-prefix={{MUSL_INSTALL}} --disable-shared --enable-debug
  make -C tyche-musl/ -j `nproc`  CFLAGS="-static -Os -Wl,-z,norelro"
  make -C tyche-musl/ install

build-libcxx:
  cd llvm-project/libcxx && cmake -DLIBCXX_HAS_MUSL_LIBC=ON -DCMAKE_C_COMPILER=clang -DCMAKE_CXX_COMPILER=clang++ -DLIBCXX_ENABLE_STATIC_ABI_LIBRARY=TRUE -DCMAKE_INSTALL_PREFIX={{LIBCXX_INSTALL}}

refresh:
  @rm -rf musl-build
  @just clean
  @just build-musl
  @just build-libcxx

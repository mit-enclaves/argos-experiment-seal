# Path to the musl-gcc

MUSL_GCC := justfile_directory() + "/musl-build/bin/musl-gcc"

MUSL_INSTALL := justfile_directory() + "/musl-build" 

clean:
    make -C tyche-musl clean
    make -C tyche-redis clean

build-musl:
	cd tyche-musl && ./configure --prefix={{MUSL_INSTALL}} --exec-prefix={{MUSL_INSTALL}} --disable-shared
	make -C tyche-musl/
	make -C tyche-musl/ install

build-redis-server:
	make -C tyche-redis/ CC={{MUSL_GCC}} CFLAGS="-static -Os" LDFLAGS="-static" USE_JEMALLOC=no redis-server


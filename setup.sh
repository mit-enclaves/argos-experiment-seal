current_dir=$(dirname "$(readlink -f "$0")")"
export ROOT="$current_dir/toolchain-root"

export CC="clang"
export CXX="clang++"
export CFLAGS="-nostdinc -nodefaultlibs --sysroot $ROOT -isystem $ROOT/include -v" #-I$ROOT/include/c++/v1"
export CXXFLAGS="$CFLAGS -nostdinc++ -I$ROOT/include/c++/v1"
export LDFLAGS="-static $ROOT/lib/crt1.o $ROOT/lib/crti.o $ROOT/lib/crtn.o -nostdlib --sysroot $ROOT -L$ROOT/lib -lc -lpthread -lc++ -lc++abi"
export LD_LIBRARY_PATH="$ROOT/lib"

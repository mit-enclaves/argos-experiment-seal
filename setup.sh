export MUSL_ROOT="/home/drean/tyche-experiment-seal/musl-build"
export LLVM_ROOT="/home/drean/tyche-experiment-seal/llvm-project/build"

export CC="clang"
export CXX="clang++"
export CFLAGS="-nostdinc -nodefaultlibs --sysroot $MUSL_ROOT -isystem $MUSL_ROOT/include -v" #-I$LLVM_ROOT/include/c++/v1"
export CXXFLAGS="$CFLAGS -nostdinc++ -I$LLVM_ROOT/include/c++/v1"
export LDFLAGS="-static $MUSL_ROOT/lib/crt1.o $MUSL_ROOT/lib/crti.o $MUSL_ROOT/lib/crtn.o -nostdlib --sysroot $MUSL_ROOT -L$MUSL_ROOT/lib -lc -lpthread -L$LLVM_ROOT/lib -lc++ -lc++abi"
export LD_LIBRARY_PATH="$LLVM_ROOT/lib"

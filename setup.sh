export MUSL_ROOT="/home/drean/tyche-experiment-seal/musl-build"

export CFLAGS="-nodefaultlibs --sysroot $MUSL_ROOT -isystem $MUSL_ROOT/include"
export LDFLAGS="-nostdlib --sysroot $MUSL_ROOT -L $MUSL_ROOT/lib -lc"

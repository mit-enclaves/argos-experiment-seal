# tyche-experiment-seal
Setup to run a series of FHE-based applications using Microsoft SEAL libraries on top of Argos (fork of Tyche).

## Initialise The Repository

```bash
git submodule update --init --recursive
```

## Build everything

```bash
just all
```

To quickly rebuild only the modified components:
```bash
just refresh-light
```

To rebuild everything from scratch:
```bash
just refresh
```

To clean everything:
```bash
just clean
```

### Build Without Tyche

If you need to build without Tyche support (for debugging purposes):
```bash
just refresh-no-tyche        # Complete rebuild without Tyche
just refresh-no-tyche-light  # Quick rebuild without Tyche
```
All syscall handler will be replace by normal syscalls

All built artifacts are placed in the `toolchain-root` directory.


# Details

## Custom runtime
Argos only provides a bare execution environments without support for dynamic libraries nor system calls.
As a result, we implement a static custom runtime mostly composed of forked of standard libraries that are modified to implement system calls and interface with Argos.

First we implement a custom MUSL library that implements a handler for any system calls used by our applications.
It also manages memory allocation by statically allocating a large pool of memory at startup and then using a dynamic memory allocator to manage memory when requested by the application.

We then compile the llvm version of libcxx satically and against our custom MUSL library.
That makes it possible for Argos to support C++ applications.

We then provide a modified version of the SEAL library to statically compile against our custom libraries.

Static compilation of large libraries and application is especially finecky as we lose the support of the dynamic linker to resolve symbols.
That means libraries need to be linked a specific order.
You can find the detail for the subtle compilations steps in the `llvm-toolchain.cmake` and `seal-toolchain.cmake` files.

Finally, these repository offer to compile three FHE-based applications using our custom SEAL runtime:
- SEAL Benchmarks, a collection of simple benchmarks for FHE circuits evaluations from a [previous paper](https://arxiv.org/pdf/2301.07041) from Viand et. al..
- SEAL PIR, an implementation of a private information retrieval protocol.
- SEAL APSI, an implementation of a private set intersection protocol.

All built artifacts will be placed in the `toolchain-root` directory.

## Building individual components

1. Build the custom MUSL library:
```bash
just setup-musl
just build-musl
```

To Build a version of the MUSL library that permorms system calls instead of implementing a custom handler (for debugging purposes), run:
```bash
just setup-musl
just build-musl-no-tyche
```

2. Build the custom libcxx:
```bash
just setup-libcxx
just build-libcxx
```

3. Build SEAL:
```bash
just setup-seal
just build-seal
```

4. Build additional SEAL-based applications (optional):
```bash
# Build SEAL benchmarks
just build-seal-bench

# Build SealPIR
just build-seal-pir

# Build SEAL APSI (Requires Kuku, JsonCPP, and Flatbuffers)
just build-seal-apsi
```

Once again, all built artifacts will be placed in the `toolchain-root` directory.

## STrace Parser Tool

The repository includes a Python-based strace parser tool (`strace_mmap_parser.py`) that helps analyze memory usage patterns of applications. This tool is particularly useful for:

- Determining the maximum memory usage of an application
- Calculating optimal memory pool sizes for the buddy allocator
- Analyzing brk and mmap system call patterns
- Determining appropriate configuration parameters for the Tyche runtime

### Usage

The strace tool should be run on version of the application that perform actual system calls (compiled using one the no-tyche targets).
```bash
./strace_mmap_parser.py <executable>
```

For example, to analyze the SEAL benchmarks:
```bash
./strace_mmap_parser.py ./toolchain-root/bin/sealbench
```

### Output Information

The tool provides several key metrics:

- Final and maximum mmap usage
- Maximum memory bucket usage and overhead
- Largest single allocation
- Recommended parameters for:
  - Buddy-system allocator configuration
  - Memory pool settings (NB_PAGES and MAX_ALLOC_LOG2)
  - KernelConfidential segment size
  - BRK_NB_PAGES configuration

This information is crucial for properly configuring the memory subsystem in the Tyche runtime environment.


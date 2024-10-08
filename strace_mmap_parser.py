#!/usr/bin/env python3

import re
import sys
import subprocess
from collections import defaultdict
import math

PAGE_SIZE = 0x1000

def find_bucket_size(size):
    bucket_size = PAGE_SIZE
    while bucket_size < size:
        bucket_size *= 2
    return bucket_size

def parse_strace_output(command):
    current_usage = 0
    current_bucket_usage = 0
    max_usage = 0
    max_bucket_usage = 0
    max_single_allocation = 0
    mmap_regions = {}
    max_usage_regions = {}
    over_subtraction_count = defaultdict(int)
    specific_over_subtraction_info = []
    mmap_pattern = re.compile(r'mmap\((.*?)\)\s+=\s+(0x[0-9a-f]+)')
    munmap_pattern = re.compile(r'munmap\((0x[0-9a-f]+),\s*(\d+)\)')
    initial_brk = None
    final_brk = None
    brk_pattern = re.compile(r'brk\((0x[0-9a-f]+)\)\s+=\s+(0x[0-9a-f]+)')
    
    process = subprocess.Popen(['strace', '-f'] + command,
                               stderr=subprocess.PIPE,
                               universal_newlines=True)

    unrecognized_syscalls = defaultdict(int)
    unrecognized_syscall_lines = []
 
    for line in process.stderr:
        mmap_match = mmap_pattern.search(line)
        munmap_match = munmap_pattern.search(line)
        brk_match = brk_pattern.search(line)
        if mmap_match:
            args = mmap_match.group(1).split(', ')
            size = int(args[1])
            bucket_size = find_bucket_size(size)
            addr = mmap_match.group(2)
            mmap_regions[addr] = size
            current_usage += size
            current_bucket_usage += bucket_size
            if current_usage > max_usage:
                max_usage = current_usage
                max_bucket_usage = current_bucket_usage
                max_usage_regions = mmap_regions.copy()
            max_single_allocation = max(max_single_allocation, size)
            #print(f"mmap: +{size} bytes, Current: {current_usage} bytes")
            continue
        elif munmap_match:
            addr = munmap_match.group(1)
            size = int(munmap_match.group(2))
            if addr in mmap_regions:
                orig_size = mmap_regions[addr]
                if size > orig_size:
                    over_subtraction = size - orig_size
                    over_subtraction_count[over_subtraction] += 1
                    if over_subtraction == 4028:
                        specific_over_subtraction_info.append((addr, orig_size, size))
                    size = orig_size  # Prevent over-subtraction
                    # print(f"Warning: Attempted over-subtraction at address {addr}. "
                    #       f"Unmapping {size} bytes from a {orig_size} byte region. "
                    #       f"Over-subtraction by {over_subtraction} bytes.")
                #elif size < orig_size:
                    # print(f"Partial unmapping at address {addr}: "
                    #       f"Unmapping {size} bytes from a {orig_size} byte region.")
                mmap_regions[addr] -= size
                if mmap_regions[addr] <= 0:
                    del mmap_regions[addr]
                current_usage -= size
                #print(f"munmap: -{size} bytes, Current: {current_usage} bytes")
            # else:
                #print(f"Warning: munmap for unknown region {addr}")
            continue
        elif brk_match:
            brk_addr = int(brk_match.group(2), 16)
            if initial_brk is None:
                initial_brk = brk_addr
            final_brk = brk_addr
            continue
        else:
            # Extract syscall name
            syscall_match = re.match(r'(\w+)\(', line)
            if syscall_match:
                syscall_name = syscall_match.group(1)
                unrecognized_syscalls[syscall_name] += 1
                unrecognized_syscall_lines.append(line)
            continue

    process.wait()
    print(f"\nFinal mmap usage: {current_usage} bytes")
    print(f"Maximum mmap usage: {max_usage} bytes")
    print(f"Maximum mmap bucket usage: {max_bucket_usage} bytes : {(((max_bucket_usage-max_usage) / max_usage) * 100):.2f}% overhead")
    print(f"Largest single mmap allocation: {max_single_allocation} bytes")
    print(f"Remaining mapped regions: {len(mmap_regions)}")

    print(f"\nRecommended parameters for the buddy-system allocator:")
    print(f"Minimum tree size: 0x{find_bucket_size(max_bucket_usage):x} bytes")
    print(f"Recommended parameters for mempool: NB_PAGES 0x{int(find_bucket_size(max_bucket_usage) / PAGE_SIZE):x}, MAX_ALLOC_LOG2 = {int(math.floor(math.log2(find_bucket_size(max_bucket_usage))))}")
    print(f"Size KernelConfidential segment in manifest {find_bucket_size(max_bucket_usage)}")

    # print("\nOver-subtraction statistics:")
    # for over_subtraction, count in sorted(over_subtraction_count.items()):
    #     print(f"Over-subtraction by {over_subtraction} bytes occurred {count} times")
    
    # print("\nDetailed information on 4028-byte over-subtractions:")
    # for addr, orig_size, unmapped_size in specific_over_subtraction_info:
    #     print(f"Address: {addr}, Original size: {orig_size}, Attempted unmapped size: {unmapped_size}")
    
    # print("\nMemory map at peak usage (with closest power of 2):")
    # size_count = defaultdict(int)
    # for size in max_usage_regions.values():
    #     size_count[size] += 1
    
    # sorted_sizes = sorted(size_count.items(), key=lambda x: x[0], reverse=True)
    
    # print("\nSize distribution of mapped regions:")
    # for size, count in sorted_sizes:
    #     closest_pow2 = closest_power_of_2(size)
    #     print(f"Size: {size} bytes, Count: {count}, Closest power of 2: {closest_pow2} bytes "
    #           f"(Difference: {size - closest_pow2} bytes)")

    brk_size = 0
    if initial_brk is not None and final_brk is not None:
        brk_size = final_brk - initial_brk
        print(f"\nBrk usage:")
        print(f"Initial brk: 0x{initial_brk:x}")
        print(f"Final brk: 0x{final_brk:x}")
        print(f"Brk region size: 0x{brk_size:x} bytes ({brk_size} bytes)")
    print(f"\nRecommended size for BRK_NB_PAGES : {int(((brk_size+PAGE_SIZE-1) / PAGE_SIZE))}")

    print("\nUnrecognized syscalls:")
    for syscall, count in sorted(unrecognized_syscalls.items(), key=lambda x: x[1], reverse=True):
        print(f"{syscall}: {count} times")

    # print("\nUnrecognized syscall lines:")
    # for line in unrecognized_syscall_lines:
    #     print(line)

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: ./strace_mmap_parser.py <command> [args...]")
        sys.exit(1)
    
    command = sys.argv[1:]
    parse_strace_output(command)

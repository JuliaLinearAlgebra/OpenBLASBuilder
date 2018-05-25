using BinaryBuilder

# Collection of sources required to build OpenBLAS
sources = [
    "https://github.com/xianyi/OpenBLAS/archive/v0.3.0.tar.gz" =>
    "cf51543709abe364d8ecfb5c09a2b533d2b725ea1a66f203509b21a8e9d8f1a1",
]

# Bash recipe for building across all platforms
script = raw"""
# We always want threading
flags="USE_THREAD=1 GEMM_MULTITHREADING_THRESHOLD=50 NO_AFFINITY=1"

# We are cross-compiling
flags="${flags} CROSS=1 HOSTCC=$CC_FOR_BUILD PREFIX=/ CROSS_SUFFIX=${target}-"

# We need to use our basic objconv, not a prefixed one:
flags="${flags} OBJCONV=objconv"

if [[ ${nbits} == 64 ]]; then
    # If we're building for a 64-bit platform, engage ILP64
    flags="${flags} INTERFACE64=1 SYMBOLSUFFIX=64_ LIBPREFIX=libopenblas64_"
fi

# Set BINARY=32 on 32-bit platforms
if [[ ${nbits} == 32 ]]; then
    flags="${flags} BINARY=32"
fi

# Set BINARY=64 on x86_64 platforms (but not AArch64 or powerpc64le)
if [[ ${target} == x86_64-* ]]; then
    flags="${flags} BINARY=64"
fi

# Use 16 threads unless we're on an i686 arch:
if [[ ${target} == i686* ]]; then
    flags="${flags} NUM_THREADS=8"
else
    flags="${flags} NUM_THREADS=16"
fi

# On Intel architectures, engage DYNAMIC_ARCH
if [[ ${proc_family} == intel ]]; then
    flags="${flags} DYNAMIC_ARCH=1"
# Otherwise, engage a specific target
elif [[ ${target} == aarch64-* ]]; then
    flags="${flags} TARGET=ARMV8"
elif [[ ${target} == arm-* ]]; then
    flags="${flags} TARGET=ARMV7"
elif [[ ${target} == powerpc64le-* ]]; then
    flags="${flags} TARGET=POWER8"
fi

# Enter the fun zone
cd ${WORKSPACE}/srcdir/OpenBLAS-0.3.0/

# Build the library
make ${flags} -j${nproc}

# Install the library
make ${flags} PREFIX=$prefix install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line.
platforms = [
    Windows(:i686),
    Windows(:x86_64),
    Linux(:i686, :glibc),
    Linux(:x86_64, :glibc),
    Linux(:aarch64, :glibc),
    Linux(:armv7l, :glibc),
    Linux(:powerpc64le, :glibc),
    MacOS()
]

# The products that we will ensure are always built
products(prefix) = [
    LibraryProduct(prefix, ["libopenblasp-r0", "libopenblas64_p-r0"], :libopenblas)
]

# Dependencies that must be installed before this package can be built
dependencies = [
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, "OpenBLAS", sources, script, platforms, products, dependencies)

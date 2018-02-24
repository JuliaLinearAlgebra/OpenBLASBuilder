using BinaryBuilder

# Collection of sources required to build OpenBLAS
sources = [
    "https://github.com/xianyi/OpenBLAS/archive/v0.2.20.tar.gz" =>
    "5ef38b15d9c652985774869efd548b8e3e972e1e99475c673b25537ed7bcf394",
]

# Bash recipe for building across all platforms
script = raw"""
# We always want threading
flags="USE_THREAD=1 GEMM_MULTITHREADING_THRESHOLD=50 NO_AFFINITY=1"

# We are cross-compiling
flags="${flags} CROSS=1 HOSTCC=$CC_FOR_BUILD PREFIX=/ CROSS_SUFFIX=${target}-"

# We need to use our basic objconv, not a prefixed one:
flags="${flags} OBJCONV=objconv"

if [[ ${target} == *64-*-* ]]; then
    # If we're building for a 64-bit platform, engage ILP64
    flags="${flags} INTERFACE64=1 SYMBOLSUFFIX=64_ LIBPREFIX=libopenblas64_"
fi

# Set BINARY=32 on i686 platforms and armv7l
if [[ ${target} == i686* ]] || [[ ${target} == arm-* ]]; then
    flags="${flags} BINARY=32"
fi

# Set BINARY=64 on x86_64 platforms
if [[ ${target} == x86_64-* ]]; then
    flags="${flags} BINARY=64"
fi

# Use 16 threads unless we're on an i686 arch:
if [[ ${target} == i686* ]]; then
    flags="${flags} NUM_THREADS=8"
else
    flags="${flags} NUM_THREADS=16"
fi

# On i686 and x86_64 architectures, engage DYNAMIC_ARCH
if [[ ${target} == i686* ]] || [[ ${target} == x86_64* ]]; then
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
cd ${WORKSPACE}/srcdir/OpenBLAS-0.2.20/

# Build the library
make ${flags} -j${nproc}

# Install the library
make ${flags} PREFIX=$prefix install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line.
platforms = [
    BinaryProvider.Windows(:i686),
    BinaryProvider.Windows(:x86_64),
    BinaryProvider.Linux(:i686, :glibc),
    BinaryProvider.Linux(:x86_64, :glibc),
    BinaryProvider.Linux(:aarch64, :glibc),
    BinaryProvider.Linux(:armv7l, :glibc),
    BinaryProvider.Linux(:powerpc64le, :glibc),
    BinaryProvider.MacOS()
]

# The products that we will ensure are always built
products(prefix) = [
    LibraryProduct(prefix, ["libopenblasp-r0", "libopenblas64_p-r0"])
]

# Dependencies that must be installed before this package can be built
dependencies = [
]


# Parse out some command-line arguments
BUILD_ARGS = ARGS

# This sets whether we should build verbosely or not
verbose = "--verbose" in BUILD_ARGS
BUILD_ARGS = filter!(x -> x != "--verbose", BUILD_ARGS)

# This flag skips actually building and instead attempts to reconstruct a
# build.jl from a GitHub release page.  Use this to automatically deploy a
# build.jl file even when sharding targets across multiple CI builds.
only_buildjl = "--only-buildjl" in BUILD_ARGS
BUILD_ARGS = filter!(x -> x != "--only-buildjl", BUILD_ARGS)

if !only_buildjl
    # If the user passed in a platform (or a few, comma-separated) on the
    # command-line, use that instead of our default platforms
    if length(BUILD_ARGS) > 0
        platforms = platform_key.(split(BUILD_ARGS[1], ","))
    end
    info("Building for $(join(triplet.(platforms), ", "))")

    # Build the given platforms using the given sources
    autobuild(pwd(), "OpenBLAS", platforms, sources, script, products, dependencies=dependencies)
else
    # If we're only reconstructing a build.jl file on Travis, grab the information and do it
    if !haskey(ENV, "TRAVIS_REPO_SLUG") || !haskey(ENV, "TRAVIS_TAG")
        error("Must provide repository name and tag through Travis-style environment variables!")
    end

    repo_name = ENV["TRAVIS_REPO_SLUG"]
    tag_name = ENV["TRAVIS_TAG"]
    product_hashes = product_hashes_from_github_release(repo_name, tag_name; verbose=verbose)
    bin_path = "https://github.com/$(repo_name)/releases/download/$(tag_name)"
    dummy_prefix = Prefix(pwd())
    print_buildjl(pwd(), products(dummy_prefix), product_hashes, bin_path)

    if verbose
        info("Writing out the following reconstructed build.jl:")
        print_buildjl(STDOUT, product_hashes; products=products(dummy_prefix), bin_path)
    end
end

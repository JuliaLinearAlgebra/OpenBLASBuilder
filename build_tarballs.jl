using BinaryBuilder

sources = [
    "https://github.com/xianyi/OpenBLAS/archive/v0.2.20.tar.gz" =>
    "5ef38b15d9c652985774869efd548b8e3e972e1e99475c673b25537ed7bcf394",
]

# We always want threading
common_flags  = "USE_THREAD=1 GEMM_MULTITHREADING_THRESHOLD=50 NO_AFFINITY=1 "

# We are cross-compiling
common_flags *= "CROSS=1 HOSTCC=\$CC_FOR_BUILD PREFIX=/ "

# We need to use our basic objconv, not a prefixed one:
common_flags *= "OBJCONV=objconv "

# These flags are for if we are building with ILP64 support
ilp64_flags  = "BINARY=64 INTERFACE64=1 SYMBOLSUFFIX=64_ LIBPREFIX=libopenblas64_"

# From these flags, define the complete flags we'll apply to each platform
platform_data = Dict(
    Linux(:x86_64)   => ("DYNAMIC_ARCH=1 NUM_THREADS=16 $(ilp64_flags)", "libopenblas64_p-r0"),
    Linux(:i686)     => ("DYNAMIC_ARCH=1 BINARY=32 NUM_THREADS=8", "libopenblasp-r0"),
    Linux(:aarch64)  => ("TARGET=ARMV8 NUM_THREADS=16 $(ilp64_flags)", "libopenblas64_p-r0"),
    Linux(:armv7l)   => ("TARGET=ARMV7 BINARY=32 NUM_THREADS=16", "libopenblasp-r0"),
    Linux(:ppc64le)  => ("TARGET=POWER8 NUM_THREADS=16 $(ilp64_flags)", "libopenblas64_p-r0"),
    MacOS()          => ("DYNAMIC_ARCH=1 NUM_THREADS=16 $(ilp64_flags) AR=x86_64-apple-darwin14-ar ", "libopenblas64_p-r0"),
    Windows(:x86_64) => ("DYNAMIC_ARCH=1 NUM_THREADS=16 $(ilp64_flags)", "libopenblas64_p-r0"),
    Windows(:i686)   => ("DYNAMIC_ARCH=1 BINARY=32 NUM_THREADS=8", "libopenblasp-r0"),
)

# Add CROSS_SUFFIX to each platform
platform_data = Dict(k => (v[1] * "CROSS_SUFFIX=$(triplet(k))- ", v[2]) for (k, v) in platform_data)

# Add common_flags to each platform
platform_data = Dict(k => (v[1] * common_flags, v[2]) for (k, v) in platform_data)

for platform in keys(platform_data)
    platform_flags, libname = platform_data[platform]

    # Construct our script
    script = """
    cd \${WORKSPACE}/srcdir/OpenBLAS-0.2.20/
    make $(platform_flags) -j\${nproc}
    make $(platform_flags) install
    """

    products = prefix -> [
        LibraryProduct(prefix, libname)
    ]

    autobuild(pwd(), "OpenBLASBuilder", [platform], sources, script, products)
end


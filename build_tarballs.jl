using BinaryBuilder

sources = [
    "https://github.com/xianyi/OpenBLAS/archive/v0.2.20.tar.gz" =>
    "5ef38b15d9c652985774869efd548b8e3e972e1e99475c673b25537ed7bcf394",
]

common_flags = "USE_THREAD=1 GEMM_MULTITHREADING_THRESHOLD=50 NO_AFFINITY=1 CROSS=1 HOSTCC=\$CC_FOR_BUILD PREFIX=/"
ilp64_flags  = "INTERFACE64=1 SYMBOLSUFFIX=64_ LIBPREFIX=libopenblas64_"
platform_data = Dict(
    Linux(:x86_64)   => ("DYNAMIC_ARCH=1 BINARY=64 NUM_THREADS=16 $(ilp64_flags)", "libopenblas64_p-r0"),
    Linux(:i686)     => ("DYNAMIC_ARCH=1 BINARY=32 NUM_THREADS=8", "libopenblasp-r0"),
    Linux(:aarch64)  => ("TARGET=ARMV8 BINARY=64 NUM_THREADS=16 $(ilp64_flags)", "libopenblas64_p-r0"),
    Linux(:armv7l)   => ("TARGET=ARMV7 BINARY=32 NUM_THREADS=16", "libopenblasp-r0"),
    Linux(:ppc64le)  => ("TARGET=POWER8 BINARY=64 NUM_THREADS=16 $(ilp64_flags)", "libopenblas64_p-r0"),
    MacOS()          => ("DYNAMIC_ARCH=1 BINARY=64 NUM_THREADS=16 $(ilp64_flags)", "libopenblas64_p-r0"),
    Windows(:x86_64) => ("DYNAMIC_ARCH=1 BINARY=64 NUM_THREADS=16 $(ilp64_flags)", "libopenblas64_p-r0"),
    Windows(:i686)   => ("DYNAMIC_ARCH=1 BINARY=32 NUM_THREADS=8", "libopenblasp-r0"),
)

for platform in keys(platform_data)
    platform_flags, libname = platform_data[platform]

    flags = "$(common_flags) $(platform_flags) CROSS_SUFFIX=$(triplet(platform))-"
    script = """
    cd \${WORKSPACE}/srcdir
    cd OpenBLAS-0.2.20/
    make $(flags) -j\${nproc}
    make $(flags) install
    """

    products = prefix -> [
        LibraryProduct(prefix, libname)
    ]

    autobuild(pwd(), "OpenBLASBuilder", [platform], sources, script, products)
end


using BinaryBuilder
using SHA

# Define what we're downloading, where we're putting it
src_name = "OpenBLAS"
src_vers = "0.2.20"
src_url = "https://github.com/xianyi/OpenBLAS/archive/v$(src_vers).tar.gz"
src_hash = "5ef38b15d9c652985774869efd548b8e3e972e1e99475c673b25537ed7bcf394"

# First, download the source, store it in ./downloads/
src_path = joinpath(pwd(), "downloads", basename(src_url))
try mkpath(dirname(src_path)) end
download_verify(src_url, src_hash, src_path; verbose=true)

# Our build products will go into ./products
out_path = joinpath(pwd(), "products")
rm(out_path; force=true, recursive=true)
mkpath(out_path)

# Build for all our platforms
products = Dict()
for platform in supported_platforms()
    target = platform_triplet(platform)

    # We build in a platform-specific directory
    build_path = joinpath(pwd(), "build", target)
    try mkpath(build_path) end

    cd(build_path) do
        # For each build, create a temporary prefix we'll install into, then package up
        temp_prefix() do prefix
            # Unpack the source into our build directory
            unpack(src_path, build_path; verbose=true)

            # Enter the directory we just unpacked
            cd("$(src_name)-$(src_vers)") do
                # We expect these outputs from our build steps
                libnettle = LibraryProduct(prefix, "libnettle")
                nettlehash = ExecutableProduct(prefix, "nettle-hash")

                # We build using `make`
                steps = [
                    `make clean`,
                    `make -j$(min(Sys.CPU_CORES + 1,8))`,
                    `make install`
                ]
                dep = Dependency(src_name, [libnettle, nettlehash], steps, platform, prefix)
                build(dep; verbose=true)
            end

            # Once we're built up, go ahead and package this prefix out
            tarball_path, tarball_hash = package(prefix, joinpath(out_path, src_name); platform=platform, verbose=true)
            products[target] = (basename(tarball_path), tarball_hash)
        end
    end
    
    # Finally, destroy the build_path
    rm(build_path; recursive=true)
end

# In the end, dump an informative message telling the user how to download/install these
info("Hash/filename pairings:")
for target in keys(products)
    filename, hash = products[target]
    println("    :$(platform_key(target)) => (\"\$bin_prefix/$(filename)\", \"$(hash)\"),")
end

# OpenBLASBuilder

[![Build Status](https://gitlab.com/BinaryBuilder.jl/OpenBLASBuilder/badges/master/pipeline.svg)](https://gitlab.com/BinaryBuilder.jl/OpenBLASBuilder/pipelines/23843870)

This is an example repository showing how to construct a "builder" repository for a binary dependency.  Using a combination of [`BinaryBuilder.jl`](https://github.com/JuliaLinearAlgebra/BinaryBuilder.jl), [GitLab CI](https://about.gitlab.com/features/gitlab-ci-cd/), and [GitHub releases](https://docs.travis-ci.com/user/deployment/releases/), we are able to create a fully-automated, github-hosted binary building and serving infrastructure.

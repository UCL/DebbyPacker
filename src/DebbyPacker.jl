module DebbyPacker

abstract AbstractPackage
abstract AbstractSource
abstract AbstractDebianizer
abstract AbstractBuilder

type Package <: AbstractPackage
    name::String
    license::String
    version::VersionNumber

    homepage::String
    maintainer::String
    build_depends::Vector{String}
    depends::Vector{String}

    source::AbstractSource
    #= debianize::AbstractDebianizer =#
    #= build::AbstractBuilder =#

    function Package(name::String, source::AbstractSource;
            license::String="MIT", version::VersionNumber=v"0.0.0", homepage::String="",
            maintainer::String="", build_depends::Vector{String}=String[],
            depends::Vector{String}=String[])
        new(name, license, version, url, maintainer, build_depends, depends, source)
    end
end


function prep_source(pack::AbstractPackage, workdir::String="workspace"; kwargs...)
  prep_source(pack, pack.source, workdir; kwargs...)
end

include("convenience.jl")
include("GitSource.jl")

end # module

module DebbyPacker

export Package, GitSource, TarSource, prepare, build, test, ModifySource

abstract AbstractPackage
abstract AbstractSource
abstract AbstractDebianizer
abstract AbstractBuilder
abstract AbstractTest
abstract AbstractPublish

type Package <: AbstractPackage
    name::String
    license::String
    version::VersionNumber

    homepage::String
    maintainer::String
    email::String
    build_depends::Vector
    depends::Vector
    section::String
    priority::String
    distribution::String
    binaries::Vector{Dict{Symbol, Any}}
    changes::Vector
    urgency::String

    source::AbstractSource
    debianize::AbstractDebianizer
    build::AbstractBuilder

    function Package(
            name::String, source::AbstractSource, debianize::AbstractDebianizer,
            build::AbstractBuilder;
            license::String="MIT", version::VersionNumber=v"0.0.0", homepage::String="",
            maintainer::String="", email::String="", build_depends::Vector=String[],
            depends::Vector=String[], section::String="devel", priority::String="optional",
            distribution::String="unstable", changes::Vector=String[], urgency::String="low",
            kwargs...)
      new(
        name, license, version, homepage, maintainer, email, build_depends, depends,
        section, priority, distribution, get_binaries(name; kwargs...), changes, urgency,
        source, debianize, build
      )
    end
end

function prepare_source(pack::AbstractPackage, workdir::String="workspace"; kwargs...)
  prepare_source(pack, pack.source, workdir; kwargs...)
end
function control(pack::AbstractPackage; kwargs...)
  control(pack, pack.debianize; kwargs...)
end
function install(pack::AbstractPackage; kwargs...)
  install(pack, pack.debianize; kwargs...)
end
function rules(pack::AbstractPackage; kwargs...)
  rules(pack, pack.debianize, pack.build; kwargs...)
end
function prepare(pack::AbstractPackage, workdir="workspace"; kwargs...)
  prepare_source(pack, workdir; kwargs...)
  debianize(pack, pack.debianize, workdir, kwargs...)
end


include("convenience.jl")
include("GitSource.jl")
include("TarSource.jl")
include("ModifySource.jl")
include("debianize.jl")
include("docker.jl")

# Default debianizer is just a place holder
function Package(name::String, source::AbstractSource, builder=:CMake;
    build_flags=nothing, extra_build=[], kwargs...)
  if builder == :CMake || builder == :cmake
    buildme = CMakeBuilder(build_flags, extra_build)
  else
    buildme = MakeBuilder(extra_build)
  end
  Package(name, source, Debianizer(), buildme; kwargs...)
end

function build(machine::RudeOil.Machine, package::AbstractPackage, workdir="workspace")
  activate(machine) do vm
    container, cmds = make(package, workdir)
    for cmd in cmds
      vm |> container |> cmd |> run
    end
  end
end

end # module

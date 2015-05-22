module DebbyPacker
using RudeOil

export Package, GitSource, TarSource, prepare, build, test, ModifySource, Publisher, publish

abstract AbstractPackage
abstract AbstractSource
abstract AbstractDebianizer
abstract AbstractBuilder
abstract AbstractTest
abstract AbstractPublisher

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

    image::RudeOil.AbstractImage

    function Package(
            name::String, source::AbstractSource, debianize::AbstractDebianizer,
            build::AbstractBuilder;
            license::String="MIT", version::VersionNumber=v"0.0.0", homepage::String="",
            maintainer::String="", email::String="", build_depends::Vector=String[],
            depends::Vector=String[], section::String="devel", priority::String="optional",
            distribution::String="trusty", changes::Vector=String[], urgency::String="low",
            kwargs...)
      packages = ["dh-make", "build-essential", "devscripts", "cdbs"]
      base = RudeOil.image("packaging", "ubuntu:14.10", packages=packages)
      base.base.name = {
        "precise" => "12.04", "trusty" => "ubuntu:14.04", "utopic" => "ubuntu:14.10",
        "vivid" => "ubuntu:15.04"
      }[distribution]
      new(
        name, license, version, homepage, maintainer, email, build_depends, depends,
        section, priority, distribution, get_binaries(name; kwargs...), changes, urgency,
        source, debianize, build, base
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
include("builders.jl")
include("docker.jl")
include("publish.jl")

# Default debianizer is just a place holder
function Package(name::String, source::AbstractSource, builder=:CMake;
    build_flags=nothing, extra_build=[], kwargs...)
  if builder == :CMake || builder == :cmake
    buildme = CMakeBuilder(build_flags, extra_build)
  elseif builder == :Python || builder == :python
    buildme = PythonBuilder(extra_build)
  else
    buildme = MakeBuilder(extra_build)
  end
  Package(name, source, Debianizer(), buildme; kwargs...)
end

function build(machine::RudeOil.AbstractMachine, package::AbstractPackage, workdir="workspace")
  activate(machine) do vm
    container, cmds = make(package, workdir)
    for cmd in cmds
      vm |> container |> cmd |> run
    end
  end
end

end # module

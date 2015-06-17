module DebbyPacker
using RudeOil

export Package, prepare, build, test, Publisher, publish
export GitSource, TarSource, SourceList, ModifySource, FileSource
import Base: download

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
            section::String="devel", priority::String="optional",
            distribution::String="trusty", changes::Vector=String[], urgency::String="low",
            kwargs...)
      packages = ["dh-make", "build-essential", "devscripts", "cdbs"]
      base = RudeOil.image("packaging", "ubuntu:14.10", packages=packages)
      base.base.name = {
        "precise" => "12.04", "trusty" => "ubuntu:14.04", "utopic" => "ubuntu:14.10",
        "vivid" => "ubuntu:15.04"
      }[distribution]
      new(
        name, license, version, homepage, maintainer, email, build_depends,
        section, priority, distribution, get_binaries(name; kwargs...), changes, urgency,
        source, debianize, build, base
      )
    end
end

function prepare_source(pack::AbstractPackage, workdir::String="workspace";
    from_scratch=false, kwargs...)
  if from_scratch && isdir(build)
    rm(build; recursive=true)
  end
  download(pack, pack.source, workdir; kwargs...)
  tar(pack, pack.source, workdir; kwargs...)
end

function tar(package::AbstractPackage, ::AbstractSource, workdir::String; kwargs...)
  const name = package_name(package)
  const build = builddir(package, workdir)
  const source = sourcedir(package, workdir)
  const tar = tarfile(package, workdir)
  cd(dirname(source)) do
    run(`tar -czvf $tar --exclude .git* $name`)
  end
  cd(build) do
    run(`tar -xvf $tar`)
  end
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
include("SourceList.jl")
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

function build(machine::RudeOil.AbstractMachine, package::AbstractPackage, workdir="workspace";
    kwargs...)
  activate(machine) do vm
    container, cmds = make(package, workdir; kwargs...)
    for cmd in cmds
      vm |> container |> cmd |> run
    end
  end
end

end # module

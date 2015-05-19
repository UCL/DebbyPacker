type TarSource <: DebbyPacker.AbstractSource
  filename::String
  url::String
end
TarSource(url::String) = TarSource(basename(url), dirname(url))

# Downloads a tarfile and untars it
# It expects archive should contain a single directory
function prepare_source(
    package::DebbyPacker.AbstractPackage, source::TarSource, workdir::String; kwargs...)
  const build = DebbyPacker.builddir(package, workdir)
  const tar = DebbyPacker.tarfile(package, workdir)
  const name = DebbyPacker.package_name(package)

  mkpath(build)
  isfile(tar) || download(source.url * "/" * source.filename, joinpath(build, tar))
  cd(build) do
    if !isdir(name)
      dirname = split(readchomp(`tar -tf $tar`), "\n")[1]
      run(`tar -xvf $tar`)
      mv(dirname, name)
    end
  end
end

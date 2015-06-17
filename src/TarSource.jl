type TarSource <: AbstractSource
  filename::String
  url::String
end
TarSource(url::String) = TarSource(basename(url), dirname(url))

# Downloads a tarfile and untars it
# It expects archive should contain a single directory
function download(package::AbstractPackage, source::TarSource, workdir::String; kwargs...)
  const src = sourcedir(package, workdir)
  const presource = dirname(src)
  const tar = joinpath(presource, source.filename)

  mkpath(presource)
  isfile(tar) || download(source.url * "/" * source.filename, tar)
  cd(presource) do
    if !isdir(src)
      dir = split(readchomp(`tar -tf $tar`), "\n")[1]
      run(`tar -xvf $tar`)
      mv(dir, basename(src))
    end
  end
end

type FileSource <: AbstractSource
  filename::String
  url::String
end

FileSource(url::String) = FileSource(basename(url), dirname(url))

# Downloads a tarfile and untars it
# It expects archive should contain a single directory
function download(package::AbstractPackage, source::FileSource, workdir::String; kwargs...)
  const src = sourcedir(package, workdir)
  const tar = joinpath(src, source.filename)

  mkpath(src)
  isfile(tar) || download(source.url * "/" * source.filename, tar)
end

# Source comes from git
# Input is URL to git + possible tag, commit, ...
immutable type GitSource <: AbstractSource
    url::String
    commit::String
    GitSource(u::String, c::String="master") = new(u, c)
end
GitSource(u::String, v::VersionNumber) = GitSource(u, "v$v")

function prepare_source(package::AbstractPackage, gitter::GitSource, workdir::String;
    from_scratch=false, kwargs...)
  const name = package_name(package)
  const build = builddir(package, workdir)
  const source = sourcedir(package, workdir)
  const tar = tarfile(package, workdir)
  if from_scratch && isdir(build)
    rm(build; recursive=true)
  end
  mkpath(source)

  isdir(joinpath(source, ".git")) || run(`git clone $(gitter.url) $source`)

  cd(source) do
    if length(gitter.commit) > 0
      run(`git checkout $(gitter.commit)`)
    end
  end

  cd(dirname(source)) do
    run(`tar -czvf $tar --exclude .git* $name`)
  end
  cd(build) do
    run(`tar -xvf $tar`)
  end
end



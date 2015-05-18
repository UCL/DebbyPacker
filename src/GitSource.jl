# Source comes from git
# Input is URL to git + possible tag, commit, ...
immutable type GitSource <: AbstractSource
    url::String
    commit::String
    GitSource(u::String, c::String="master") = new(u, c)
end
GitSource(u::String, v::VersionNumber) = GitSource(u, "v$v")

function prep_source(package::AbstractPackage, gitter::GitSource, workdir::String;
    from_scratch=false, kwargs...)
  const build = builddir(package, workdir)
  const source = sourcedir(package, workdir)
  if from_scratch && isdir(build)
    rm(build; recursive=true)
  end
  mkpath(source)

  isdir(joinpath(source, ".git")) || run(`git clone $(gitter.url) $source`)

  cd(sourcedir) do
    if length(gitter.version)
      run(`git checkout $(gitter.version)`)
    end
  end

  cd(joinpath(builddir, "source")) do
    run(`tar -czvf $tarfile --exclude .git* $name`)
  end
  cd(builddir) do
    run(`tar -xvf $tarfile`)
  end
end



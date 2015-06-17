# Source comes from git
# Input is URL to git + possible tag, commit, ...
immutable type GitSource <: AbstractSource
    url::String
    commit::String
    GitSource(u::String, c::String="master") = new(u, c)
end
GitSource(u::String, v::VersionNumber) = GitSource(u, "v$v")

function download(package::AbstractPackage, gitter::GitSource, workdir::String; kwargs...)
  const source = sourcedir(package, workdir)
  mkpath(source)
  isdir(joinpath(source, ".git")) || run(`git clone $(gitter.url) $source`)
  cd(source) do
    if length(gitter.commit) > 0
      run(`git checkout $(gitter.commit)`)
    end
  end
end

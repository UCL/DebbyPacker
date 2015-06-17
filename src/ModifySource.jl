type ModifySource <: AbstractSource
  original::AbstractSource
  cmd::Base.AbstractCmd
end

function download(package::AbstractPackage, source::ModifySource, workdir::String; kwargs...)
  const name = package_name(package)
  const build = builddir(package, workdir)
  download(package, source.original, workdir; kwargs...)

  cd(joinpath(build, "source", name)) do
    run(source.cmd)
  end
end

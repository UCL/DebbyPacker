type ModifySource <: AbstractSource
  original::AbstractSource
  cmd::Base.AbstractCmd
end

function prepare_source(package::AbstractPackage, source::ModifySource, workdir::String;
    from_scratch=false, kwargs...)

  const name = package_name(package)
  const build = builddir(package, workdir)
  const tar = tarfile(package, workdir)
  prepare_source(package, source.original, workdir; from_scratch=from_scratch, kwargs...)

  cd(joinpath(build, name)) do
    run(source.cmd)
  end

  cd(build) do
    run(`tar -czvf $tar $name`)
  end
end

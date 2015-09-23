# Information needed for publishing
type Publisher <: AbstractPublisher
  # Launchpad id
  id::String
  # PPA where to put stuff, from user with id above
  ppa::String
  # GPG-key on current system registered with ubuntu
  gpgkey::String
end
function publish(vm::RudeOil.MachineEnv, publisher::Publisher, package::AbstractPackage,
    workdir::String="workspace")
  const name = package_name(package)
  const debname = "$(package.name)_$(package.version)"
  const build = builddir(package, workdir)

  const gpgkey = publisher.gpgkey
  open(joinpath(build, "secret-$gpgkey.asc"), "w") do file
    write(file, readall(`gpg --export-secret-keys -a $gpgkey`))
  end
  open(joinpath(build, "$gpgkey.asc"), "w") do file
    write(file, readall(`gpg --export -a $gpgkey`))
  end

  c = container(package, workdir)
  c.workdir = "/$name"
  vm |> c |> [
    `gpg --allow-secret-key-import --import secret-$gpgkey.asc`
    `gpg --import $gpgkey.asc`
    `debsign --re-sign $(debname)_source.changes -k $gpgkey`
    `dput -f ppa:$(publisher.id)/$(publisher.ppa) $(debname)_source.changes`
  ] |> run
end
publish(machine::RudeOil.AbstractMachine, args...) = publish(activate(machine), args...)

using RudeOil

function container(package::AbstractPackage, base, workdir="workspace")
  const name = package_name(package)
  const build = builddir(package, workdir)

  if is(base, nothing)
    base = RudeOil.image("packaging", "ubuntu:14.10",
        packages=["dh-make", "build-essential", "devscripts", "cdbs"])
  end

  env = {:LOGNAME => :RSDT, :DEBFULLNAME => package.maintainer, :EMAIL => package.email}
  # all dependencies except those declared in this here package
  packages = setdiff(
     [package.build_depends; package.depends],
     map(x -> x[:package], package.binaries)
  )
  image = RudeOil.image(name, base; packages=packages, env=env, volume="/$name")

  base |> image |> Container(volume=(build, "/$name"), workdir="/$name/$name")
end

function dh_make(package::AbstractPackage; base=nothing, workdir="workspace")
  const name = package_name(package)
  const tar = tarfile(package, workdir)

  if length(package.license) > 0
    `dh_make -i -a -r cdbs -l -f /$name/$(basename(tar)) -c $(package.license)`
  else
    `dh_make -i -a -r cdbs -l -f /$name/$(basename(tar))`
  end
end

dh_build(::AbstractPackage, args...) = `dpkg-buildpackage $args`
debuild(::AbstractPackage, args...) = `debuild -us -uc -S $args`

type Builder <: AbstractBuilder; end

function make(package::AbstractPackage, workdir="workspace"; kwargs...)
  make(package, package.build, workdir; kwargs...)
end
function make(package::AbstractPackage, builder::AbstractBuilder, workdir::String;
    base=nothing, source=true, binaries=true, make=true)
  cmds = Cmd[]
  if make; push!(cmds, dh_make(package, base=base, workdir=workdir)); end
  if binaries; push!(cmds, dh_build(package)); end
  if source; push!(cmds, debuild(package)); end

  container(package, base, workdir), cmds
end

function test(func::Function, vm::RudeOil.MachineEnv, package::AbstractPackage, workdir)
  const name = package_name(package)
  c = container(package, nothing, workdir)
  c.workdir = "/$name"
  if isa(c.image, RudeOil.BuildImage)
    vm |> c.image |> run
  end
  c.interactive = true
  open(RudeOil.command(vm, c), "w", STDOUT) do stream
    write(stream, "dpkg -i $(package.name)*.deb\n" * func(name))
  end
end
function test(func::Function, machine::RudeOil.Machine, package::AbstractPackage, workdir)
  vm = activate(machine)
  test(func, vm, package, workdir)
end

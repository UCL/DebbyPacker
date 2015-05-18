export debian_file

function debian_file(name, args...)
  mkpath("debian")
  open(joinpath("debian", name), "w") do stream
    for u in args
      println(stream, u)
    end
  end
end

type Debianizer <: AbstractDebianizer end

# Creates a control file for a source package declaring one or more binary packages
function control(package::Package, debianize::AbstractDebianizer; kwargs...)
  # Create list of lines
  args = String[
    "Source: $(package.name)",
    "Section: $(package.section)",
    "Priority: $(package.priority)"
  ]
  if length(package.email) > 0 && length(package.maintainer) > 0
    push!(args, "Maintainer: $(package.maintainer) <$(package.email)>")
  elseif length(package.maintainer) > 0
    push!(args, "Maintainer: $(package.maintainer)")
  end
  push!(args, "Standards-Version: 3.9.5")
  if length(package.homepage) > 0; push!(args, "Homepage: $(package.homepage)"); end

  build_depends = join(package.build_depends, ", ")
  if length(build_depends) > 0
    push!(args, "Build-Depends: debhelper (>=9), $build_depends")
  else
    push!(args, "Build-Depends: debhelper (>=9)")
  end

  for binary in package.binaries
    name = pop!(binary, :package, package.name)
    desc = pop!(binary, :description, "")
    arch = pop!(binary, :architecture, "any")
    push!(args, "")
    push!(args, "Package: $name")
    push!(args, "Architecture: $arch")
    for (key, value) in binary
      key = "$(uppercase(string(key)[1]))$(lowercase(string(key)[2:end]))"
      push!(args, "$key: $value")
    end
    if length(desc) > 0; push!(args, "Description: $desc"); end
  end

  # now call function
  debian_file("control", args...)
end

function change(package::Package, args...)
  if length(args) == 0
    args = ["  * No reported changes"]
  else
    args = ["  * $u" for u in args]
  end
  debian_file("changelog",
    "$(package.name) ($(package.version)) $(package.distribution); urgency=$(package.urgency)",
    "",
    args...,
    "",
    " -- $(package.maintainer) <$(package.email)>  $(strftime("%a, %d %b %Y %T %z", time()))"
  )
end

type MakeBuilder <: AbstractBuilder
  args
  MakeBuilder(args=[]) = new(args)
end
type CMakeBuilder <: AbstractBuilder
  flags
  args
  CMakeBuilder(flags="", args=[]) = new(flags, args)
end
function rules(package::AbstractPackage, ::AbstractDebianizer, build::CMakeBuilder; kwargs...)
  specials = String["include /usr/share/cdbs/1/class/cmake.mk"]
  if length(build.flags) > 0
    push!(specials, "DEB_CMAKE_EXTRA_FLAGS=$(build.flags)")
  end
  debian_file("rules",
    "#! /usr/bin/make -f",
    "include /usr/share/cdbs/1/rules/debhelper.mk",
    specials..., build.args...
  )
end
function rules(package::AbstractPackage,::AbstractDebianizer, build::MakeBuilder; kwargs...)
  debian_file("rules",
    "#! /usr/bin/make -f",
    "include /usr/share/cdbs/1/rules/debhelper.mk",
    "include /usr/share/cdbs/1/class/makefile.mk",
    build.args...
  )
end

# Adds the different debian files
function debianize(pack::AbstractPackage, ::AbstractDebianizer, workdir="workspace"; kwargs...)
  const name = package_name(pack)
  const build = builddir(pack, workdir)
  cd(joinpath(build, name)) do
    control(pack)
    rules(pack)
    change(pack, pack.changes...)
  end
end

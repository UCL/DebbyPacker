type MakeBuilder <: AbstractBuilder
  args
  MakeBuilder(args=[]) = new(args)
end

function rules(package::AbstractPackage,::AbstractDebianizer, build::MakeBuilder; kwargs...)
  debian_file("rules",
    "#! /usr/bin/make -f",
    "include /usr/share/cdbs/1/rules/debhelper.mk",
    "include /usr/share/cdbs/1/class/makefile.mk",
    build.args...
  )
end

type CMakeBuilder <: AbstractBuilder
  flags
  args
  CMakeBuilder(flags="", args=[]) = new(flags, args)
end

function rules(package::AbstractPackage, ::AbstractDebianizer, build::CMakeBuilder; kwargs...)
  specials = String["include /usr/share/cdbs/1/class/cmake.mk"]
  if (!isa(build.flags, Nothing)) && length(build.flags) > 0
    push!(specials, "DEB_CMAKE_EXTRA_FLAGS=$(build.flags)")
  end
  debian_file("rules",
    "#! /usr/bin/make -f",
    "include /usr/share/cdbs/1/rules/debhelper.mk",
    specials..., build.args...
  )
end

type PythonBuilder <: AbstractBuilder
  args
  PythonBuilder(args=[]) = new(args)
end

function rules(package::AbstractPackage, ::AbstractDebianizer, build::PythonBuilder; kwargs...)
  debian_file("rules",
    "#! /usr/bin/make -f",
    "DEB_PYTHON_SYSTEM=pysupport",
    "include /usr/share/cdbs/1/rules/debhelper.mk",
    "include /usr/share/cdbs/1/class/python-distutils.mk",
    build.args...
  )
end

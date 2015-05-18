# Formats package and version into a standard string
package_name(package::Package) = package_name(package.name, package.version)
package_name(package::String, version::VersionNumber) = "$package-$version"
# Creates standard work-directory name
builddir(package::Package, workdir::String) = abspath(joinpath(workdir, package_name(package)))
# Creates standard tar-file name
function tarfile(package::Package, workdir::String)
  joinpath(builddir(package, workdir), "$(package.name)_$(package.version).orig.tar.gz")
end
function sourcedir(package::Package, workdir::String)
  joinpath(builddir(package, workdir), "source", package_name(package))
end

# Converts from kwargs for list of dictionaries
# Each dictionary specifies a binary package
function get_binaries(name::String; kwargs...)
  # Transform variable keyword arguments into binary packages
  current = Dict{Symbol, String}()
  binaries = Dict{Symbol, String}[]

  # Adds to list of packages, making sure a package name is available
  function add_package(current, binaries)
    if !haskey(current, :package); current[:package] = name end
    push!(binaries, current)
  end

  for (key, value) in kwargs
    if isa(value, Array) || isa(value, Tuple)
      value = join(value, if key == :description; "\n" else ", " end)
    else
      value = string(value)
    end

    if key == :package && length(current) > 0
      add_package(current, binaries)
      current = {key => string(value)}
    else
      current[key] = value
    end
  end
  if length(current) > 0; add_package(current, binaries) end
  if length(binaries) == 0; push!(binaries, {:package => name}) end
  binaries
end

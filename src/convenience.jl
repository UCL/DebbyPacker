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

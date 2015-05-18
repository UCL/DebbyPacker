facts("Clone a git repo, create a tar file and a source directory") do
  this_package = Pkg.dir("DebbyPacker")
  pack = package(
    "DebbyPacker", GitSource(this_package)
  )
end

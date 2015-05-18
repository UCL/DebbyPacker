facts("Clone a git repo, create a tar file and a source directory") do
  url = "file:///" * Pkg.dir("DebbyPacker")
  pack = DebbyPacker.Package("DebbyPacker", DebbyPacker.GitSource(url, "5c894bf"))


  context("Check name, buildir, tarfile and such") do
    workdir = joinpath("/", "yo")
    tar = DebbyPacker.tarfile(pack, workdir)
    build = DebbyPacker.builddir(pack, workdir)
    source = DebbyPacker.sourcedir(pack, workdir)

    @fact build[1:length(workdir)] => workdir
    @fact source[1:length(build)] => build
    @fact tar[1:length(build)] => build
    @fact tar => joinpath(build, basename(tar))
  end

  context("Runs prepare_source on DebbyPacker local repo") do
    workdir = mktempdir()
    name = DebbyPacker.package_name(pack)
    tar = DebbyPacker.tarfile(pack, workdir)
    try
      DebbyPacker.prepare_source(pack, workdir; from_scratch=true)

      @fact joinpath(workdir, name) => isdir
      @fact joinpath(workdir, name, name) => isdir
      @fact joinpath(workdir, name, name, "LICENSE.md") => isfile
      @fact joinpath(workdir, name, name, "src", "DebbyPacker.jl") => isfile
      @fact tar => isfile

      # does not throw on second run
      @fact DebbyPacker.prepare_source(pack, workdir; from_scratch=true) => anyof(anything, nothing)
    finally
      rm(workdir; recursive=true)
    end
  end

end

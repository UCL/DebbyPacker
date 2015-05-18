facts("Adding debianfiles") do
  context("Debian file in debdir") do
    path = mktempdir()
    lines = "hello", "world"
    try
      cd(path) do
        debian_file("myfile", lines...)
        @fact joinpath("Debian", "myfile") => isfile

        actual = joinpath("Debian", "myfile") |> readall |> x -> split(x, "\n")
        @fact actual => [lines..., ""]
      end
    finally
      rm(path; recursive=true)
    end
  end

  context("list of binaries from kwargs...") do
    @fact DebbyPacker.get_binaries("this") => [{:package => "this"}]

    actual = DebbyPacker.get_binaries("this", description="hello")
    @fact actual  => [{:package => "this", :description => "hello"}]

    # still one package, butw with different name
    actual = DebbyPacker.get_binaries("this", package="this-dev", description="hello")
    @fact actual  => [{:package => "this-dev", :description => "hello"}]

    # now two packages
    actual = DebbyPacker.get_binaries("this",
      description="hello", architecture="all",
      package="this-dev", description="world")
    expected = [
      {:package => "this", :description => "hello", :architecture => "all"},
      {:package => "this-dev", :description => "world"}
    ]
    @fact actual  => expected
  end

  context("control") do
    url = "file:///" * Pkg.dir("DebbyPacker")
    pack = DebbyPacker.Package(
      "DebbyPacker", DebbyPacker.GitSource(url, "5c894bf"),
      package="DebbyPacker-dev", description="this", architecture="all"
    )
    path = mktempdir()
    try
      cd(path) do
        control(pack)
        @fact joinpath("debian", "control") => isfile
        text = readall(joinpath("debian", "control"))
        @fact text => ismatch(r"Source: DebbyPacker")
        @fact text => ismatch(r"Priority: optional")
        @fact text => ismatch(r"Description: this")
        @fact text => ismatch(r"\n\nPackage: DebbyPacker-dev")
      end
    finally
      rm(path, recursive=true)
    end
  end
end


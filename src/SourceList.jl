import Base: haskey, getindex, setindex!, start, done, next
# A number of sources are put together
type SourceList <: AbstractSource
  sources::Dict{Any, AbstractSource}
  # helps to build a list of sources
  SourceList(args...) = new(Dict{Any, AbstractSource}(args...))
end

function SourceList(main::AbstractSource, args...)
  result = SourceList(args...)
  result[""] = main
  result
end

getindex(d::SourceList, key) = getindex(d.sources, key)
setindex!(d::SourceList, value::AbstractSource, key) = setindex!(d.sources, value, key)
haskey(d::SourceList, key) = haskey(d.sources, key)
start(d::SourceList) = start(d.sources)
done(d::SourceList, state) = done(d.sources, state)
next(d::SourceList, state) = next(d.sources, state)

type SubPackage <: AbstractPackage
  parent::AbstractPackage
  subdir::String
end

sourcedir(p::SubPackage, workdir::String) = joinpath(sourcedir(p.parent, workdir), p.subdir)

function download(package::AbstractPackage, sources::SourceList, workdir::String; kwargs...)
  if haskey(sources, "")
    download(package, sources[""], workdir; kwargs...)
  end
  for (dir, source) in sources
    path = string(dir)
    if length(path) == 0 continue end
    if path[1] == '/'
      path = path[2:end]
    end
    println("downaload $source")
    download(SubPackage(package, path), source, workdir; kwargs...)
  end
end


module DebbyPackerTests
using DebbyPacker
using FactCheck: facts, context, @fact, greater_than, not, @fact_throws, anyof, anything

import Base: ismatch
ismatch(regex::String) = x -> ismatch(Regex(regex), x)
ismatch(regex::Regex) = x -> ismatch(regex, x)
contains(item) = x -> item ∈ x

#= include("GitSource.jl") =#
include("debianize.jl")

end

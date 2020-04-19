module Pickle

if VERSION < v"1.1"
    isnothing(::Nothing) = true
    isnothing(::Any) = false
end

include("./readarg.jl")
include("./writearg.jl")
include("./opcode.jl")
using .OpCodes

include("./pickler.jl")
include("./unpickle.jl")

end # module

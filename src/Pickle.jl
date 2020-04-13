module Pickle

if VERSION < v"1.1"
    isnothing(::Nothing) = true
    isnothing(::Any) = false
end

include("./readarg.jl")
include("./opcode.jl")
include("./unpickle.jl")

end # module

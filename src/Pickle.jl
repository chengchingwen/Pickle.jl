module Pickle

if VERSION < v"1.1"
    isnothing(::Nothing) = true
    isnothing(::Any) = false
end

include("./readarg.jl")
include("./writearg.jl")
include("./opcode/opcode.jl")
using .OpCodes

include("./mt_table.jl")
include("./deserializer.jl")

include("./torch/torch.jl")
using .Torch

end # module

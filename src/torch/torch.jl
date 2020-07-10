module Torch

import ..Pickle: AbstractPickle, protocol, isbinary

include("./storage.jl")
include("./torch_load.jl")
include("./torch_save.jl")

end

using Pickle.Torch
using Strided

const torch_tests = [
  "load",
  "load_zip",
  "save",
  "prebuild"
]

@testset "Torch" begin

  for t in torch_tests
    fp = joinpath(dirname(@__FILE__), "torch_$t.jl")
    @info "Test Torch $(uppercase(t))"
    include(fp)
  end

end

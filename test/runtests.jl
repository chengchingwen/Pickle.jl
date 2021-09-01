using Test, Serialization, Documenter, Pickle, PyCall, SparseArrays

DocMeta.setdocmeta!(Pickle, :DocTestSetup, :(using Pickle); recursive=true)

include("./pyscript.jl")
include("./torch/thscript.jl")

builtin_type_samples = Dict(
  "str" => "Julia!",
  "int" => 42,
  "bool" => Dict(
    true => false,
    false => true,
  ),
  "float" => 3.1415926,
  "bytes" => b"1234",
  "tuple" => (1, 2.0, "3", b"4"),
  "set" => Set((1,2,3,12,21)),
  "bigint" => 1234567890987654321012345678909876543210,
  "list" => ["February", 14, 2012],
)

const tests = [
  "load",
  "store",
  "np",
  "sparse",
]

Pickle.BATCHSIZE[] = 3

@testset "Pickle" begin
  @info "BATCHSIZE is set to: $(Pickle.BATCHSIZE[])"
  @info "Test doctest"
  doctest(Pickle)

  for t in tests
    fp = joinpath(dirname(@__FILE__), "test_$t.jl")
    @info "Test $(uppercase(t))"
    include(fp)
  end

  @info "Test Pickle.Torch"
  include("./torch/torch.jl")

end

using CondaPkg
# copy CondaPkg.toml to temporal pkg environment
testproj_dir = dirname(Base.load_path()[1])
cp(joinpath(@__DIR__, "CondaPkg.toml"), joinpath(testproj_dir, "CondaPkg.toml"))

using Test, Serialization, Documenter, Pickle, PythonCall, SparseArrays

DocMeta.setdocmeta!(Pickle, :DocTestSetup, :(using Pickle); recursive=true)

include("./pyscript.jl")
if haskey(ENV, "TEST_TORCH")
    include("./torch/thscript.jl")
end

builtin_type_samples = Dict(
  "str" => "Julia!",
  "int" => 42,
  "bool" => Dict(
    true => false,
    false => true,
  ),
  "float" => 3.1415926,
  "bytes" => b"1234²",
  "tuple" => (1, 2.0, "3", b"4"),
  "set" => Set((1,2,3,12,21)),
  "bigint" => 1234567890987654321012345678909876543210,
  "list" => ["February", 14, 2012],
  "unicode" => "Résumé",
)

const tests = [
  "load",
  "store",
  "np",
  "sparse",
]

Pickle.BATCHSIZE[] = 3

const doctestfilters = [
    r"{([a-zA-Z0-9]+,\s?)+[a-zA-Z0-9]+}",
    r"(Array{[a-zA-Z0-9]+,\s?1}|Vector{[a-zA-Z0-9]+})",
    r"(Array{[a-zA-Z0-9]+,\s?2}|Matrix{[a-zA-Z0-9]+})",
]

@show CondaPkg.STATE

@testset "Pickle" begin
  @info "BATCHSIZE is set to: $(Pickle.BATCHSIZE[])"
  @info "Test doctest"
  doctest(Pickle; doctestfilters=doctestfilters)

  for t in tests
    fp = joinpath(dirname(@__FILE__), "test_$t.jl")
    @info "Test $(uppercase(t))"
    include(fp)
  end

  if haskey(ENV, "TEST_TORCH")
    @info "Test Pickle.Torch"
    include("./torch/torch.jl")
  end

end

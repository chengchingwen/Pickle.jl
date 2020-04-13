using Test, Documenter, Pickle

DocMeta.setdocmeta!(Pickle, :DocTestSetup, :(using Pickle); recursive=true)

@testset "Pickle" begin
  doctest(Pickle)
end

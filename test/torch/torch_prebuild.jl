@testset "PREBUILD" begin

    for f in readdir(joinpath(@__DIR__, "test_bin"))
        file = joinpath(@__DIR__, "test_bin", f)
        jlpkl = Pickle.Torch.THload(file)
        pypkl = pyconvert(Dict{String, Py}, libtorch.load(file))
        @test keys(jlpkl) == keys(pypkl)
        for k in keys(jlpkl)
            @test jlpkl[k] ≈ pyconvert(Any, pypkl[k].numpy())
        end
    end

end

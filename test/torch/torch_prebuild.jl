@testset "PREBUILD" begin

  for f in readdir(joinpath(@__DIR__, "test_bin"))
    file = joinpath(@__DIR__, "test_bin", f)
    x1,   x2 = Pickle.Torch.THload(file)
    px1, px2 = libtorch.load(file)
    @test x1[2] ≈ px1[2].numpy()
    @test x2[2] ≈ px2[2].numpy()
  end

end

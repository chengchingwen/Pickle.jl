@testset "STORE" begin

  mktempdir() do path
    for i in 0:4
      file = joinpath(path, "builtin_type_p$i.jpkl")
      store(file, builtin_type_samples; proto=i)
      @test check_bts(file)
    end
  end

end

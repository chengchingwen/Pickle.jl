@testset "LOAD" begin

  for i in 0:4
    # test loading pre-saved files
    @info "protocal $i"
    bts = load("./test_pkl/builtin_type_p$(i).pkl")
    @test builtin_type_samples == bts

    # test loading from string
    sbts = loads(py"pystores(builtin_type_samples, $i)")
    @test builtin_type_samples == sbts
  end

  mktempdir() do path
    for i in 0:4
      @info "protocal $i"
      # test loading from directly saved file
      file = joinpath(path, "pybuiltin_type_p$i.pkl")
      py"pystore($file, builtin_type_samples, $i)"
      @test builtin_type_samples == load(file)
    end
  end

end

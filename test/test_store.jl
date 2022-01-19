@testset "STORE" begin

  mktempdir() do path
    for i in 0:4
      @info "protocal $i"
      # test directly save
      file = joinpath(path, "builtin_type_p$i.jpkl")
      store(file, builtin_type_samples; proto=i)
      @test check_bts(file)

      # test saving to string
      sbts = stores(builtin_type_samples; proto=i)
      sfile = joinpath(path, "string_builtin_type_p$i")
      open(sfile, "w+") do f
        write(f, sbts)
      end
      @test scheck_bts(sfile)
    end
  end

end

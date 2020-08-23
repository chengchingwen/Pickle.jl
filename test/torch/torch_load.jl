@testset "LOAD" begin

  mktempdir() do path
    @testset "array" begin
      file = joinpath(path, "arr.bin")
      x0 = libtorch.randn(())
      x1 = libtorch.randn((5,))
      x2 = libtorch.randn((3,3))
      x3 = libtorch.randn((4,3,2))
      x4 = libtorch.randn((5,4,3,2))
      libtorch.save(Dict("x0"=>x0, "x1"=>x1,
               "x2"=>x2, "x3"=>x3, "x4"=>x4), file)
      load_arr = Torch.THload(file)
      @test load_arr["x0"] ≈ x0.numpy()
      @test load_arr["x1"] ≈ x1.numpy()
      @test load_arr["x2"] ≈ x2.numpy()
      @test load_arr["x3"] ≈ x3.numpy()
      @test load_arr["x4"] ≈ x4.numpy()
    end

    x = libtorch.randn(10,10)
    @testset "slice" begin
      file = joinpath(path, "slice.bin")
      x_slice = random_slice(x)
      libtorch.save([x, x_slice], file)
      test_load_slice = Torch.THload(file)
      load_x, load_slice = test_load_slice
      @test load_x ≈ x.numpy()
      @test load_slice ≈ x_slice.numpy()
      @test pointer(load_x.parent) == pointer(load_slice.parent)
    end

    @testset "stride" begin
      file = joinpath(path, "stride.bin")
      x_stride = random_stride(x)
      libtorch.save([x, x_stride], file)
      test_load_stride = Torch.THload(file)
      load_x, load_stride = test_load_stride
      @test load_x ≈ x.numpy()
      @test load_stride ≈ x_stride.numpy()
      @test pointer(load_x.parent) == pointer(load_stride.parent)
    end

    @testset "reshape" begin
      file = joinpath(path, "reshape.bin")
      x_reshape = x.reshape(2,5,5,2)
      libtorch.save([x, x_reshape], file)
      test_load_reshape = Torch.THload(file)
      load_x, load_reshape = test_load_reshape
      @test load_x ≈ x.numpy()
      @test load_reshape ≈ x_reshape.numpy()
      @test pointer(load_x.parent) == pointer(load_reshape.parent)
    end

    @testset "offset" begin
      file = joinpath(path, "offset.bin")
      x_offset = pyslice(x.reshape(-1), 5).reshape(5, -1)
      libtorch.save([x, x_offset], file)
      test_load_offset = Torch.THload(file)
      load_x, load_offset = test_load_offset
      @test load_x ≈ x.numpy()
      @test load_offset ≈ x_offset.numpy()
      @test pointer(load_x.parent) == pointer(load_offset.parent)
    end

    @testset "mutation" begin
      file = joinpath(path, "mutate.bin")
      x1 = x.clone()
      x2 = pyslice(x1, 5)
      libtorch.save([x1, x2], file)
      test_load_mutate = Torch.THload(file)
      load_x1, load_x2 = test_load_mutate
      set!(x2, 0, 0)
      load_x2[1, :] .= 0
      @test all(iszero, load_x1[6, :])
      @test load_x1 ≈ x1.numpy()
      @test load_x2 ≈ x2.numpy()
    end

    @testset "transpose" begin
      file = joinpath(path, "transpose.bin")
      x_transpose = x.transpose(1, 0)
      libtorch.save([x, x_transpose], file)
      test_load_transpose = Torch.THload(file)
      load_x, load_transpose = test_load_transpose
      @test load_x ≈ x.numpy()
      @test load_transpose ≈ x_transpose.numpy()
      @test pointer(load_x.parent) == pointer(load_transpose)
    end

    @testset "all" begin
      file = joinpath(path, "all.bin")
      x_offset = pyslice(x.reshape(-1), 10).reshape(6, 15)
      x_stride = random_stride(x_offset)
      x_slice = random_slice(x_stride)
      x_transpose = x_slice.transpose(0,1)
      set!(x_transpose, (0,0), 0)
      libtorch.save([x, x_offset, x_stride, x_slice, x_transpose], file)
      test_load_all = Torch.THload(file)
      load_x, load_offset, load_stride, load_slice, load_transpose = test_load_all
      @test load_x ≈ x.numpy()
      @test load_offset ≈ x_offset.numpy()
      @test load_stride ≈ x_stride.numpy()
      @test load_slice ≈ x_slice.numpy()
      @test load_transpose ≈ x_transpose.numpy()
      @test pointer(load_x.parent) == pointer(load_offset.parent)
      @test pointer(load_x.parent) == pointer(load_stride.parent)
      @test pointer(load_x.parent) == pointer(load_slice.parent)
      @test pointer(load_x.parent) == pointer(load_transpose.parent)
    end

  end

end

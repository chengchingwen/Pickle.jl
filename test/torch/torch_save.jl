@testset "SAVE" begin

  mktempdir() do path
    @testset "array" begin
      file = joinpath(path, "arr.bin")
      x0 = randn(())
      x1 = randn((5,))
      x2 = randn((3,3))
      x3 = randn((4,3,2))
      x4 = randn((5,4,3,2))
      Torch.THsave(file, Dict("x0"=>x0, "x1"=>x1,
                    "x2"=>x2, "x3"=>x3, "x4"=>x4))
      save_arr = libtorch.load(file)
      @test save_arr["x0"].numpy() ≈ x0
      @test save_arr["x1"].numpy() ≈ x1
      @test save_arr["x2"].numpy() ≈ x2
      @test save_arr["x3"].numpy() ≈ x3
      @test save_arr["x4"].numpy() ≈ x4
    end

    x = randn(10, 10)
    @testset "slice" begin
      file = joinpath(path, "slice.bin")
      x_slice = @strided x[2:5, 3:8]
      Torch.THsave(file, Any[x, x_slice])
      test_save_slice = libtorch.load(file)
      save_x, save_slice = test_save_slice
      @test save_x.numpy() ≈ x
      @test save_slice.numpy() ≈ x_slice
    end

    @testset "stride" begin
      file = joinpath(path, "stride.bin")
      x_stride = @strided x[2:3:9, 1:2:8]
      Torch.THsave(file, Any[x, x_stride])
      test_save_stride = libtorch.load(file)
      save_x, save_stride = test_save_stride
      @test save_x.numpy() ≈ x
      @test save_stride.numpy() ≈ x_stride
    end

    @testset "reshape" begin
      file = joinpath(path, "reshape.bin")
      x_reshape = @strided reshape(x, (2,5,5,2))
      Torch.THsave(file, Any[x, x_reshape])
      test_save_reshape = libtorch.load(file)
      save_x, save_reshape = test_save_reshape
      @test save_x.numpy() ≈ x
      @test save_reshape.numpy() ≈ x_reshape
    end

    @testset "offset" begin
      file = joinpath(path, "offset.bin")
      x_offset = @strided reshape(reshape(x, 100)[6:end], (5, 19))
      Torch.THsave(file, Any[x, x_offset])
      test_save_offset = libtorch.load(file)
      save_x, save_offset = test_save_offset
      @test save_x.numpy() ≈ x
      @test save_offset.numpy() ≈ x_offset
    end

    @testset "mutation" begin
      file = joinpath(path, "mutation.bin")
      x1 = copy(x)
      x2 = @strided x1[6:end, :]
      Torch.THsave(file, Any[x1, x2])
      test_save_mutate = libtorch.load(file)
      save_x1, save_x2 = test_save_mutate
      set!(save_x2, 0, 0)
      x2[1, :] .= 0
      @test (get(save_x1, 5) == 0).all().numpy()[]
      @test save_x1.numpy() ≈ x1
      @test save_x2.numpy() ≈ x2
    end

    @testset "transpose" begin
      file = joinpath(path, "transpose.bin")
      x_transpose = @strided permutedims(x, (2,1))
      Torch.THsave(file, Any[x, x_transpose])
      test_save_transpose = libtorch.load(file)
      save_x, save_transpose = test_save_transpose
      @test save_x.numpy() ≈ x
      @test save_transpose.numpy() ≈ x_transpose
    end

  end

end

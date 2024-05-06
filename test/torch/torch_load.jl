@testset "LOAD" begin

    mktempdir() do path
        @testset "array" begin
            file = joinpath(path, "arr.bin")
            x0 = libtorch.randn(())
            x1 = libtorch.randn((5,))
            x2 = libtorch.randn((3,3))
            x3 = libtorch.randn((4,3,2))
            x4 = libtorch.randn((5,4,3,2))
            libtorch.save(pydict(Dict("x0"=>x0, "x1"=>x1,
                                      "x2"=>x2, "x3"=>x3, "x4"=>x4)), file;
                          _use_new_zipfile_serialization=false)
            load_arr = Torch.THload(file)
            @test load_arr["x0"] ≈ pyconvert(Any, x0.numpy())
            @test load_arr["x1"] ≈ pyconvert(Any, x1.numpy())
            @test load_arr["x2"] ≈ pyconvert(Any, x2.numpy())
            @test load_arr["x3"] ≈ pyconvert(Any, x3.numpy())
            @test load_arr["x4"] ≈ pyconvert(Any, x4.numpy())
            load_arr_lazy = Torch.THload(file; lazy=true, mmap=true)
            @test load_arr_lazy["x0"]() ≈ pyconvert(Any, x0.numpy())
            @test load_arr_lazy["x1"]() ≈ pyconvert(Any, x1.numpy())
            @test load_arr_lazy["x2"]() ≈ pyconvert(Any, x2.numpy())
            @test load_arr_lazy["x3"]() ≈ pyconvert(Any, x3.numpy())
            @test load_arr_lazy["x4"]() ≈ pyconvert(Any, x4.numpy())
        end

        x = libtorch.randn(10,10)
        @testset "slice" begin
            file = joinpath(path, "slice.bin")
            x_slice = random_slice(x)
            libtorch.save(pylist([x, x_slice]), file;
                          _use_new_zipfile_serialization=false)
            test_load_slice = Torch.THload(file)
            load_x, load_slice = test_load_slice
            @test load_x ≈ pyconvert(Any, x.numpy())
            @test load_slice ≈ pyconvert(Any, x_slice.numpy())
            @test pointer(load_x.parent) == pointer(load_slice.parent)
            test_load_lazy_slice = Torch.THload(file; lazy=true, mmap=true)
            load_x_lazy, load_slice_lazy = test_load_lazy_slice
            @test load_x_lazy() ≈ pyconvert(Any, x.numpy())
            @test load_slice_lazy() ≈ pyconvert(Any, x_slice.numpy())
            @test pointer(load_x_lazy().parent) == pointer(load_slice_lazy().parent)
        end

        @testset "stride" begin
            file = joinpath(path, "stride.bin")
            x_stride = random_stride(x)
            libtorch.save(pylist([x, x_stride]), file;
                          _use_new_zipfile_serialization=false)
            test_load_stride = Torch.THload(file)
            load_x, load_stride = test_load_stride
            @test load_x ≈ pyconvert(Any, x.numpy())
            @test load_stride ≈ pyconvert(Any, x_stride.numpy())
            @test pointer(load_x.parent) == pointer(load_stride.parent)
            test_load_lazy_stride = Torch.THload(file; lazy=true, mmap=true)
            load_x_lazy, load_stride_lazy = test_load_lazy_stride
            @test load_x_lazy() ≈ pyconvert(Any, x.numpy())
            @test load_stride_lazy() ≈ pyconvert(Any, x_stride.numpy())
            @test pointer(load_x_lazy().parent) == pointer(load_stride_lazy().parent)
        end

        @testset "reshape" begin
            file = joinpath(path, "reshape.bin")
            x_reshape = x.reshape(2,5,5,2)
            libtorch.save(pylist([x, x_reshape]), file;
                          _use_new_zipfile_serialization=false)
            test_load_reshape = Torch.THload(file)
            load_x, load_reshape = test_load_reshape
            @test load_x ≈ pyconvert(Any, x.numpy())
            @test load_reshape ≈ pyconvert(Any, x_reshape.numpy())
            @test pointer(load_x.parent) == pointer(load_reshape.parent)
            test_load_lazy_reshape = Torch.THload(file; lazy=true, mmap=true)
            load_x_lazy, load_reshape_lazy = test_load_lazy_reshape
            @test load_x_lazy() ≈ pyconvert(Any, x.numpy())
            @test load_reshape_lazy() ≈ pyconvert(Any, x_reshape.numpy())
            @test pointer(load_x_lazy().parent) == pointer(load_reshape_lazy().parent)
        end

        @testset "offset" begin
            file = joinpath(path, "offset.bin")
            x_offset = pyslice(x.reshape(-1), 5).reshape(5, -1)
            libtorch.save(pylist([x, x_offset]), file;
                          _use_new_zipfile_serialization=false)
            test_load_offset = Torch.THload(file)
            load_x, load_offset = test_load_offset
            @test load_x ≈ pyconvert(Any, x.numpy())
            @test load_offset ≈ pyconvert(Any, x_offset.numpy())
            @test pointer(load_x.parent) == pointer(load_offset.parent)
            test_load_lazy_offset = Torch.THload(file; lazy=true, mmap=true)
            load_x_lazy, load_offset_lazy = test_load_lazy_offset
            @test load_x_lazy() ≈ pyconvert(Any, x.numpy())
            @test load_offset_lazy() ≈ pyconvert(Any, x_offset.numpy())
            @test pointer(load_x_lazy().parent) == pointer(load_offset_lazy().parent)
        end

        @testset "mutation" begin
            file = joinpath(path, "mutate.bin")
            x1 = x.clone()
            x2 = pyslice(x1, 5)
            libtorch.save(pylist([x1, x2]), file;
                          _use_new_zipfile_serialization=false)
            test_load_mutate = Torch.THload(file)
            load_x1, load_x2 = test_load_mutate
            x2[0] = 0
            load_x2[1, :] .= 0
            @test all(iszero, load_x1[6, :])
            @test load_x1 ≈ pyconvert(Any, x1.numpy())
            @test load_x2 ≈ pyconvert(Any, x2.numpy())
            test_load_lazy_mutate = Torch.THload(file; lazy=true, mmap=true)
            load_x1_lazy, load_x2_lazy = test_load_lazy_mutate
            load_x2_lazy()[1, :] .= 0
            @test all(iszero, load_x1_lazy()[6, :])
            @test load_x1_lazy() ≈ pyconvert(Any, x1.numpy())
            @test load_x2_lazy() ≈ pyconvert(Any, x2.numpy())
        end

        @testset "transpose" begin
            file = joinpath(path, "transpose.bin")
            x_transpose = x.transpose(1, 0)
            libtorch.save(pylist([x, x_transpose]), file;
                          _use_new_zipfile_serialization=false)
            test_load_transpose = Torch.THload(file)
            load_x, load_transpose = test_load_transpose
            @test load_x ≈ pyconvert(Any, x.numpy())
            @test load_transpose ≈ pyconvert(Any, x_transpose.numpy())
            @test pointer(load_x.parent) == pointer(load_transpose)
            test_load_lazy_transpose = Torch.THload(file; lazy=true, mmap=true)
            load_x_lazy, load_transpose_lazy = test_load_lazy_transpose
            @test load_x_lazy() ≈ pyconvert(Any, x.numpy())
            @test load_transpose_lazy() ≈ pyconvert(Any, x_transpose.numpy())
            @test pointer(load_x_lazy().parent) == pointer(load_transpose_lazy())
        end

        @testset "all" begin
            file = joinpath(path, "all.bin")
            x_offset = pyslice(x.reshape(-1), 10).reshape(6, 15)
            x_stride = random_stride(x_offset)
            x_slice = random_slice(x_stride)
            x_transpose = x_slice.transpose(0,1)
            x_transpose[0,0] = 0
            libtorch.save(pylist([x, x_offset, x_stride, x_slice, x_transpose]), file;
                          _use_new_zipfile_serialization=false)
            test_load_all = Torch.THload(file)
            load_x, load_offset, load_stride, load_slice, load_transpose = test_load_all
            @test load_x ≈ pyconvert(Any, x.numpy())
            @test load_offset ≈ pyconvert(Any, x_offset.numpy())
            @test load_stride ≈ pyconvert(Any, x_stride.numpy())
            @test load_slice ≈ pyconvert(Any, x_slice.numpy())
            @test load_transpose ≈ pyconvert(Any, x_transpose.numpy())
            @test pointer(load_x.parent) == pointer(load_offset.parent)
            @test pointer(load_x.parent) == pointer(load_stride.parent)
            @test pointer(load_x.parent) == pointer(load_slice.parent)
            @test pointer(load_x.parent) == pointer(load_transpose.parent)
            test_load_lazy_all = Torch.THload(file; lazy=true, mmap=true)
            load_x_lazy, load_offset_lazy, load_stride_lazy, load_slice_lazy, load_transpose_lazy = test_load_lazy_all
            @test load_x_lazy() ≈ pyconvert(Any, x.numpy())
            @test load_offset_lazy() ≈ pyconvert(Any, x_offset.numpy())
            @test load_stride_lazy() ≈ pyconvert(Any, x_stride.numpy())
            @test load_slice_lazy() ≈ pyconvert(Any, x_slice.numpy())
            @test load_transpose_lazy() ≈ pyconvert(Any, x_transpose.numpy())
            @test pointer(load_x_lazy().parent) == pointer(load_offset_lazy().parent)
            @test pointer(load_x_lazy().parent) == pointer(load_stride_lazy().parent)
            @test pointer(load_x_lazy().parent) == pointer(load_slice_lazy().parent)
            @test pointer(load_x_lazy().parent) == pointer(load_transpose_lazy().parent)
        end

    end

end

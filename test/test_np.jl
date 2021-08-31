@testset "Numpy" begin

    @testset "load" begin
        @test Pickle.npyload("./test_pkl/test-np.pkl") == pyload("./test_pkl/test-np.pkl")
        @test Pickle.npyload("./test_pkl/test-np-end.pkl") == pyload("./test_pkl/test-np-end.pkl")
        @test Pickle.npyload("./test_pkl/test-np-multi.pkl") == pyload("./test_pkl/test-np-multi.pkl")

        jlnpstrings = Pickle.npyload("./test_pkl/test-np-string.pkl")
        npstrings = pyload("./test_pkl/test-np-string.pkl")
        @test jlnpstrings["little-endian"] == convert(Array{String}, collect(npstrings["little-endian"]))
        @test jlnpstrings["big-endian"] == convert(Array{String}, collect(npstrings["big-endian"]))

        jlscalars = Pickle.npyload("./test_pkl/test-np-scalar.pkl")
        # [np.uint32(4), np.int64(6), np.float16(3), np.float64(5), np.unicode_("abcα😀")]
        npscalars = collect(pyload("./test_pkl/test-np-scalar.pkl"))
        @test jlscalars[1] == tryparse(UInt32, npscalars[1].__repr__())
        @test jlscalars[2] == tryparse(Int64, npscalars[2].__repr__())
        @test jlscalars[3] == tryparse(Float16, npscalars[3].__repr__())
        @test jlscalars[4] == Float64(npscalars[4])
        @test jlscalars[5] == String(npscalars[5])

    end

end

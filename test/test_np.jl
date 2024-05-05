@testset "Numpy" begin

    @testset "load" begin
        @test Pickle.npyload("./test_pkl/test-np.pkl") == pyconvert(Array, pyload("./test_pkl/test-np.pkl"))
        @test Pickle.npyload("./test_pkl/test-np-end.pkl") == pyconvert(Vector{Array}, pyload("./test_pkl/test-np-end.pkl"))
        @test Pickle.npyload("./test_pkl/test-np-multi.pkl") == pyconvert(Vector{Array}, pyload("./test_pkl/test-np-multi.pkl"))

        jlnpstrings = Pickle.npyload("./test_pkl/test-np-string.pkl")
        npstrings = pyconvert(Dict{String, Vector{String}}, pyload("./test_pkl/test-np-string.pkl"))
        @test jlnpstrings["little-endian"] == npstrings["little-endian"]
        @test jlnpstrings["big-endian"] == npstrings["big-endian"]

        jlscalars = Pickle.npyload("./test_pkl/test-np-scalar.pkl")
        # [np.uint32(4), np.int64(6), np.float16(3), np.float64(5), np.unicode_("abcα😀")]
        npscalars = pyload("./test_pkl/test-np-scalar.pkl")
        @test jlscalars[1] == pyconvert(Any, npscalars[1])
        @test jlscalars[2] == pyconvert(Any, npscalars[2])
        @test jlscalars[3] == pyconvert(Any, npscalars[3])
        @test jlscalars[4] == pyconvert(Float64, npscalars[4])
        @test jlscalars[5] == pyconvert(String, npscalars[5])

    end

end

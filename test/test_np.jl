@testset "Numpy" begin

    @testset "load" begin
        @test Pickle.npyload("./test_pkl/test-np.pkl") == pyload("./test_pkl/test-np.pkl")
        @test Pickle.npyload("./test_pkl/test-np-end.pkl") == pyload("./test_pkl/test-np-end.pkl")
        @test Pickle.npyload("./test_pkl/test-np-multi.pkl") == pyload("./test_pkl/test-np-multi.pkl")
        @test Pickle.npyload("./test_pkl/test-np-string.pkl")["little-endian"] == convert(Array{String}, collect(pyload("./test_pkl/test-np-string.pkl")["little-endian"]))
        @test Pickle.npyload("./test_pkl/test-np-string.pkl")["big-endian"] == convert(Array{String}, collect(pyload("./test_pkl/test-np-string.pkl")["big-endian"]))
    end

end

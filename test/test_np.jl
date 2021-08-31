@testset "Numpy" begin

    @testset "load" begin
        @test Pickle.npyload("./test_pkl/test-np.pkl") == pyload("./test_pkl/test-np.pkl")
        @test Pickle.npyload("./test_pkl/test-np-end.pkl") == pyload("./test_pkl/test-np-end.pkl")
        @test Pickle.npyload("./test_pkl/test-np-multi.pkl") == pyload("./test_pkl/test-np-multi.pkl")
    end

end

@testset "LOAD" begin

  bts0 = load("./test_pkl/builtin_type_p0.pkl")
  @test builtin_type_samples == bts0
  bts1 = load("./test_pkl/builtin_type_p1.pkl")
  @test builtin_type_samples == bts1
  bts2 = load("./test_pkl/builtin_type_p2.pkl")
  @test builtin_type_samples == bts2
  bts3 = load("./test_pkl/builtin_type_p3.pkl")
  @test builtin_type_samples == bts3
  bts4 = load("./test_pkl/builtin_type_p4.pkl")
  @test builtin_type_samples == bts4

end

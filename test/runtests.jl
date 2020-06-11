using Test, Serialization, Documenter, Pickle, PyCall

DocMeta.setdocmeta!(Pickle, :DocTestSetup, :(using Pickle); recursive=true)

py"""
import pickle
builtin_type_samples = {
  'str': 'Julia!',
  'int': 42,
  'bool': {True: False, False: True},
  'float': 3.1415926,
  'bytes': b'1234',
  'tuple': (1, 2.0, '3', b'4'),
  'set': {1, 2, 3, 12, 21},
  'bigint': 1234567890987654321012345678909876543210,
  'list': ['February', 14, 2012]
}

def pyload(f):
  with open(f, "rb") as io:
    return pickle.load(io)

def pyloads(s):
  return pickle.loads(s)

def pystore(f, x, p):
  with open(f, "wb+") as io:
    return pickle.dump(x, io, protocol=p)

def pystores(x, p):
  return pickle.dumps(x, protocol=p)

def check_bts(f):
  global builtin_type_samples
  return builtin_type_samples == pyload(f)

# pre-built pickle files for testing `load`
# for i in range(5):
#   pickle.dump(x, open(f"./test_pkl/builtin_type_p{i}.pkl", "wb+"), protocol=i)
"""
pyload = py"pyload"
pyloads = py"pyloads"
pystore = py"pystore"
pystores = py"pystores"
check_bts = py"check_bts"

builtin_type_samples = Dict(
  "str" => "Julia!",
  "int" => 42,
  "bool" => Dict(
    true => false,
    false => true,
  ),
  "float" => 3.1415926,
  "bytes" => b"1234",
  "tuple" => (1, 2.0, "3", b"4"),
  "set" => Set((1,2,3,12,21)),
  "bigint" => 1234567890987654321012345678909876543210,
  "list" => ["February", 14, 2012],
)

const tests = [
  "load",
  "store",
]

Pickle.BATCHSIZE[] = 3

@testset "Pickle" begin
  @info "BATCHSIZE is set to: $(Pickle.BATCHSIZE[])"
  @info "Test doctest"
  doctest(Pickle)

  for t in tests
    fp = joinpath(dirname(@__FILE__), "test_$t.jl")
    @info "Test $(uppercase(t))"
    include(fp)
  end
end

pyexec(raw"""
import pickle
builtin_type_samples = {
  'str': 'Julia!',
  'int': 42,
  'bool': {True: False, False: True},
  'float': 3.1415926,
  'bytes': b'1234\xc2\xb2',
  'tuple': (1, 2.0, '3', b'4'),
  'set': {1, 2, 3, 12, 21},
  'bigint': 1234567890987654321012345678909876543210,
  'list': ['February', 14, 2012],
  'unicode': u"Résumé",
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

def scheck_bts(f):
  global builtin_type_samples
  with open(f, "rb") as io:
    s = io.read()
  flag = builtin_type_samples == pyloads(s)
  if not flag:
    print(builtin_type_samples)
    print(pyloads(s))
  return flag

def to_nparray(x):
  return x.toarray()

# pre-built pickle files for testing `load`
# for i in range(5):
#   with open(f"./test_pkl/builtin_type_p{i}.pkl", "wb+") as f:
#     pickle.dump(builtin_type_samples, f, protocol=i)
""", @__MODULE__)
const _pyload = pyeval("pyload", @__MODULE__)
const _pyloads = pyeval("pyloads", @__MODULE__)
const _pystore = pyeval("pystore", @__MODULE__)
const _pystores = pyeval("pystores", @__MODULE__)
const _check_bts = pyeval("check_bts", @__MODULE__)
const _scheck_bts = pyeval("scheck_bts", @__MODULE__)
const _to_nparray = pyeval("to_nparray", @__MODULE__)

pyload(args...) = pyconvert(Any, pycall(_pyload, args...))
pyloads(args...) = pyconvert(Any, pycall(_pyloads, args...))
pystore(args...) = pyconvert(Any, pycall(_pystore, args...))
pystores(args...) = pyconvert(Any, pycall(_pystores, args...))
check_bts(args...) = pyconvert(Any, pycall(_check_bts, args...))
scheck_bts(args...) = pyconvert(Any, pycall(_scheck_bts, args...))
to_nparray(args...) = pyconvert(Any, pycall(_to_nparray, args...))

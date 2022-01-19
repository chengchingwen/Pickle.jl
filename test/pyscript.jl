py"""
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
"""
pyload = py"pyload"
pyloads = py"pyloads"
pystore = py"pystore"
pystores = py"pystores"
check_bts = py"check_bts"
scheck_bts = py"scheck_bts"
to_nparray = py"to_nparray"

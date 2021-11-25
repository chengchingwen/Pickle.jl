libtorch = pyimport_conda("torch", "pytorch")
py"""
import torch
import random

# test
# 0 - 4 array-dim
# strides
# reshape
# offset
# slice
# mutation
#
# combine

def random_slice(x):
  shape = x.shape
  def randrange(s):
    s1 = random.randint(0, s-1)
    s2 = random.randint(s1+1, s)
    return (s1, s2)
  slices = list(map(randrange, shape))
  if len(shape) == 1:
    s1, s2 = slices[0]
    y = x[s1:s2]
  elif len(shape) == 2:
    s11, s12 = slices[0]
    s21, s22 = slices[1]
    y = x[s11:s12, s21:s22]
  elif len(shape) == 3:
    s11, s12 = slices[0]
    s21, s22 = slices[1]
    s31, s32 = slices[2]
    y = x[s11:s12, s21:s22, s31:s32]
  return y

def random_stride(x):
  shape = x.shape
  def randrange(s):
    s1 = random.randint(0, s//2-1)
    s2 = random.randint(s//2+2, s-1)
    si = random.randint(2, 3)
    return (s1, si, s2)
  strides = list(map(randrange, shape))
  if len(shape) == 1:
    s1, si, s2 = strides[0]
    y = x[s1:s2:si]
  elif len(shape) == 2:
    s11, si1, s12 = strides[0]
    s21, si2, s22 = strides[1]
    y = x[s11:s12:si1, s21:s22:si2]
  elif len(shape) == 3:
    s11, si1, s12 = strides[0]
    s21, si2, s22 = strides[1]
    s31, si3, s32 = strides[2]
    y = x[s11:s12:si1, s21:s22:si2, s31:s32:si3]
  return y

def pyslice(x, i):
  return x[i:]

"""
thload = libtorch.load
thsave = libtorch.save
random_slice = py"random_slice"
random_stride = py"random_stride"
pyslice = py"pyslice"

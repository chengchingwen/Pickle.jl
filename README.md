# Pickle.jl

[![Build status](https://github.com/chengchingwen/Pickle.jl/workflows/CI/badge.svg)](https://github.com/chengchingwen/Pickle.jl/actions)
[![codecov](https://codecov.io/gh/chengchingwen/Pickle.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/chengchingwen/Pickle.jl)
[![](https://img.shields.io/badge/docs-dev-blue.svg)](https://chengchingwen.github.io/Pickle.jl/dev/)


An experimental package for loading and saving object in Python Pickle and Torch Pickle format.

## Supports

### Load

1.  basic builtin types. e.g. \`Integer\`, \`String\`, \`Tuple\`, \`Dict\`, \`Vector\`, \`Set\` ...

```jl
    julia> Pickle.load(open("test.pkl"))
    Dict{Any,Any} with 6 entries:
      "int"   => 0
      "str"   => "Julia!"
      "bytes" => UInt8[0x31, 0x32, 0x33, 0x34]
      "tuple" => (1, 2.0, "3", UInt8[0x34])
      "bool"  => true
      "float" => 3.14159
```


2.  some basic support of loading `numpy.array` and `scipy.sparse.csr_matrix` with `Pickle.npyload("data.pkl")`.


3.  framework for easily analyze and implement required translation methods. For those data which are
not able to restore directly will be stored in a `Defer` object which is similar to `Expr` but is mutable.

```jl
julia> load("test/test_pkl/test-np.pkl")
Defer(:build, Defer(:reduce, Defer(:numpy.core.multiarray._reconstruct), Defer(:numpy.ndarray), (0,), UInt8[0x62]),
 (1, (3, 5), Defer(:build, Defer(:reduce, Defer(:numpy.dtype), f8, 0, 1), (3, "<", nothing, nothing, nothing, -1, -
1, 0)), false, UInt8[0x29, 0x0f, 0x9c, 0x3b, 0x11, 0x5a, 0xbf, 0x3f, 0x29, 0xa6  …  0xb8, 0x3f, 0x6b, 0x4a, 0x31, 0
xab, 0x2b, 0xc5, 0xf2, 0x3f]))

julia> dump(ans)
Pickle.Defer
  head: Symbol build
  args: Array{Any}((2,))
    1: Pickle.Defer
      head: Symbol reduce
      args: Array{Any}((4,))
        1: Pickle.Defer
          head: Symbol numpy.core.multiarray._reconstruct
          args: Array{Any}((0,))
        2: Pickle.Defer
          head: Symbol numpy.ndarray
          args: Array{Any}((0,))
        3: Tuple{Int64}
          1: Int64 0
        4: Array{UInt8}((1,)) UInt8[0x62]
    2: Tuple{Int64,Tuple{Int64,Int64},Pickle.Defer,Bool,Array{UInt8,1}}
      1: Int64 1
      2: Tuple{Int64,Int64}
        1: Int64 3
        2: Int64 5
      3: Pickle.Defer
        head: Symbol build
        args: Array{Any}((2,))
          1: Pickle.Defer
            head: Symbol reduce
            args: Array{Any}((4,))
              1: Pickle.Defer
                head: Symbol numpy.dtype
                args: Array{Any}((0,))
              2: String "f8"
              3: Int64 0
              4: Int64 1
          2: Tuple{Int64,String,Nothing,Nothing,Nothing,Int64,Int64,Int64}
            1: Int64 3
            2: String "<"
            3: Nothing nothing
            4: Nothing nothing
            5: Nothing nothing
            6: Int64 -1
            7: Int64 -1
            8: Int64 0
      4: Bool false
      5: Array{UInt8}((120,)) UInt8[0x29, 0x0f, 0x9c, 0x3b, 0x11, 0x5a, 0xbf, 0x3f, 0x29, 0xa6  …  0xb8, 0x3f, 0x6b
, 0x4a, 0x31, 0xab, 0x2b, 0xc5, 0xf2, 0x3f]
```


### Store

1. basic builtin types. e.g. \`Integer\`, \`String\`, \`Tuple\`, \`Dict\`, \`Vector\`, \`Set\` ...

```jl
julia> x
Dict{Any,Any} with 9 entries:
  "int"    => 42
  "list"   => Any["February", 14, 2012]
  "str"    => "Julia!"
  "set"    => Set(Any[2, 3, 21, 12, 1])
  "bigint" => 1234567890987654321012345678909876543210
  "bytes"  => UInt8[0x31, 0x32, 0x33, 0x34]
  "tuple"  => (1, 2.0, "3", UInt8[0x34])
  "bool"   => Dict{Any,Any}(false=>true,true=>false)
  "float"  => 3.14159

julia> store("./test.pkl", x)

julia> stores(x)
"\x80\x04}\x94(\x8c\x03int\x94K*\x8c\x04list\x94]\x94(\x8c\bFebruary\x94K\x0eM\xdc\ae\x8c\x03str\x94\x8c\x06Julia!\x94\x8c\x03set\x94\x8f\x94(K\x02K\x03K\x15K\fK\x01\x90\x8c\x06bigint\x94\x8a\x11\xea\x1e\xd9Z7\xff\xad9[e;\xa9\x80 ɠ\x03\x8c\x05bytes\x94C\x041234\x8c\x05tuple\x94(K\x01G@\0\0\0\0\0\0\0\x8c\x013\x94C\x014t\x94\x8c\x04bool\x94}\x94(\x89\x88\x88\x89u\x8c\x05float\x94G@\t!\xfbM\x12\xd8Ju."

julia> load("./test.pkl")
Dict{Any,Any} with 9 entries:
  "int"    => 42
  "list"   => Any["February", 14, 2012]
  "str"    => "Julia!"
  "set"    => Set(Any[2, 3, 21, 12, 1])
  "bigint" => 1234567890987654321012345678909876543210
  "bytes"  => UInt8[0x31, 0x32, 0x33, 0x34]
  "tuple"  => (1, 2.0, "3", UInt8[0x34])
  "bool"   => Dict{Any,Any}(false=>true,true=>false)
  "float"  => 3.14159

```


## Pickle.Torch

We also support loading/saving the tensor data from/for pytorch.

```julia
julia> Pickle.Torch.THsave("mydata.bin", [randn(3,5), randn(5)])

julia> Pickle.Torch.THload("mydata.bin")
2-element Array{Any,1}:
 [1.5106877710095366 -1.1454729135625932 … 2.06558662039955 -1.5367586535984377; 0.039481538567394656 -0.32939192495490544 … 1.3092722093574312 -2.008938993198881; -1.208358021687811 1.207098188115399 … 0.40730876859947734 1.6270781822957923]
 [-0.5909715360681883, -0.0948081699846433, -0.17734064360419854, 0.43085740457102734, -0.48091537835876497]

```

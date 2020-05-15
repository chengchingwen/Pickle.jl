# Pickle.jl

An experimental package for loading and saving object in Python Pickle format.

## Supports

1.  basic builtin types. e.g. \`Integer\`, \`String\`, \`Tuple\`, \`Dict\`, \`Vector\`

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


2.  framework for easily analyze and implement required translation methods. The unconstructable data will 
be stored in a `Defer` object which is similar to `Expr` but is mutable.

```jl
julia> Pickle.deserialize("test/test_pkl/test-np.pkl")
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

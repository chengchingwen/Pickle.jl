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


2.  framework for easy analysis and implement required translation methods

```jl
    julia> Pickle.load(open("./test-np.pkl"))
    [ Info: loading numpy.core.multiarray._reconstruct
    [ Info: loading numpy.ndarray
    [ Info: reducing <Deferred Func numpy.core.multiarray._reconstruct> with (<Deferred Func numpy.ndarray>, (0,), UInt8[0x62])
    [ Info: calling numpy.core.multiarray._reconstruct(<Deferred Func numpy.ndarray>, (0,), UInt8[0x62]; )
    ┌ Warning: numpy.core.multiarray._reconstruct is not defined in `mt_table`. deferring function call.
    └ @ Pickle ~/peter/repo/Pickle/src/defer.jl:54
    [ Info: loading numpy.dtype
    [ Info: reducing <Deferred Func numpy.dtype> with ("f8", 0, 1)
    [ Info: calling numpy.dtype(f8, 0, 1; )
    ┌ Warning: numpy.dtype is not defined in `mt_table`. deferring function call.
    └ @ Pickle ~/peter/repo/Pickle/src/defer.jl:54
    [ Info: building <Deferred numpy.dtype> with (3, "<", nothing, nothing, nothing, -1, -1, 0)
    ┌ Warning: deferring build
    └ @ Pickle ~/peter/repo/Pickle/src/unpickle.jl:250
    [ Info: building <Deferred numpy.core.multiarray._reconstruct> with (1, (3, 5), <Deferred _build <Deferred numpy.dtype>>, false, UInt8[0x29, 0x0f, 0x9c, 0x3b, 0x11, 0x5a, 0xbf, 0x3f, 0x29, 0xa6, 0x90, 0x66, 0xb8, 0xc2, 0xed, 0xbf, 0xb5, 0xb9, 0xbd, 0xe5, 0x0c, 0xa5, 0xe4, 0xbf, 0x22, 0xc4, 0xb6, 0xb7, 0xf9, 0x2e, 0xd3, 0x3f, 0xb1, 0xb6, 0x70, 0x54, 0x7c, 0x69, 0xe5, 0xbf, 0xb9, 0xde, 0x28, 0x2a, 0x6d, 0x3b, 0x05, 0x40, 0xe0, 0x84, 0xa2, 0xbd, 0xe8, 0x43, 0xf5, 0xbf, 0x84, 0xb4, 0x72, 0x80, 0x44, 0x4b, 0xd1, 0xbf,
    0xbf, 0x4d, 0x06, 0xf4, 0x28, 0x34, 0xee, 0xbf, 0xda, 0x1d, 0x1f, 0xde, 0xec, 0x7c, 0xbe, 0xbf, 0xfe, 0x26, 0xc8, 0x13, 0x33, 0x20, 0xe3, 0x3f, 0x7f, 0x4a, 0x9d, 0xce, 0x1b, 0x34, 0xc3, 0xbf, 0xcc, 0x0e, 0xa3, 0x1e, 0x09, 0x4c, 0xf2, 0xbf, 0x22, 0xa4, 0x63, 0xfb, 0x71, 0xbd, 0xb8, 0x3f, 0x6b, 0x4a, 0x31, 0xab, 0x2b, 0xc5, 0xf2, 0x3f])
    ┌ Warning: deferring build
    └ @ Pickle ~/peter/repo/Pickle/src/unpickle.jl:250
    <Deferred _build <Deferred numpy.core.multiarray._reconstruct>>
```


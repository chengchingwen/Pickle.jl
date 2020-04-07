"""
# Examples
```jldoctest
julia> using Pickle

julia> Pickle.read_uint1(IOBuffer(b"\xff"))
0xff
```
"""
read_uint1(io::IO) = read(io, UInt8)

"""
# Examples
```jldoctest
julia> using Pickle

julia> Pickle.read_uint2(IOBuffer(b"\xff\x00"))
0x00ff

julia> Pickle.read_uint2(IOBuffer(b"\xff\xff"))
0xffff
```
"""
read_uint2(io::IO) = read(io, UInt16)

"""
# Examples
```jldoctest
julia> using Pickle

julia> Pickle.read_int4(IOBuffer(b"\xff\x00\x00\x00"))
255

julia> Pickle.read_int4(IOBuffer(b"\x00\x00\x00\x80")) == -2^31
true
```
"""
read_int4(io::IO) = read(io, Int32)

"""
# Examples
```jldoctest
julia> using Pickle

julia> Pickle.read_uint4(IOBuffer(b"\xff\x00\x00\x00"))
0x000000ff

julia> Pickle.read_uint4(IOBuffer(b"\x00\x00\x00\x80")) == 2^31
true
```
"""
read_uint4(io::IO) = read(io, UInt32)

"""
# Examples
```jldoctest
julia> using Pickle

julia> Pickle.read_uint8(IOBuffer(b"\xff\x00\x00\x00\x00\x00\x00\x00"))
0x00000000000000ff

julia> Pickle.read_uint8(IOBuffer(b"\xff\xff\xff\xff\xff\xff\xff\xff")) == UInt64(2^64) - UInt64(1)
true
```
"""
read_uint8(io::IO) = read(io, UInt64)

"""
# Examples
```jldoctest
julia> using Pickle

julia> Pickle.read_stringnl(IOBuffer(b"'abcd'\nefg\n"))
"abcd"

julia> Pickle.read_stringnl(IOBuffer(b"\n"))
ERROR: no string quotes around

Stacktrace:
 [1] error(::String) at ./error.jl:33
 [2] read_stringnl(::Base.GenericIOBuffer{Base.CodeUnits{UInt8,String}}; decode::Bool, stripquotes::Bool) at /media/yuehhua/Workbench/workspace/Pickle.jl/src/readarg.jl:14
 [3] read_stringnl(::Base.GenericIOBuffer{Base.CodeUnits{UInt8,String}}) at /media/yuehhua/Workbench/workspace/Pickle.jl/src/readarg.jl:8
 [4] top-level scope at REPL[35]:1

julia> Pickle.read_stringnl(IOBuffer(b"\n"), stripquotes=false)
""

julia> Pickle.read_stringnl(IOBuffer(b"''\n"))
""

julia> Pickle.read_stringnl(IOBuffer(b"\"abcd\""))
ERROR: no newline found when trying to read stringnl
Stacktrace:
 [1] error(::String) at ./error.jl:33
 [2] read_stringnl(::Base.GenericIOBuffer{Base.CodeUnits{UInt8,String}}; decode::Bool, stripquotes::Bool) at /media/yuehhua/Workbench/workspace/Pickle.jl/src/readarg.jl:9
 [3] read_stringnl(::Base.GenericIOBuffer{Base.CodeUnits{UInt8,String}}) at /media/yuehhua/Workbench/workspace/Pickle.jl/src/readarg.jl:8
 [4] top-level scope at REPL[38]:1
```
"""
function read_stringnl(io::IO; decode=true, stripquotes=true)
    data = readline(io; keep=true)
    data[end] != '\n' && error("no newline found when trying to read stringnl")

    if stripquotes
        isquote(c) = isequal('\'')(c) || isequal('\"')(c)
        start = first(data)
        !isquote(start) && error("no string quotes around $data")

        endl = data[end-1]
        !isequal(start, endl) && error("string quote $start not found at both end of $data")

        data = data[2:end-2]
    else
        data = data[1:end-1]
    end

    if decode
        return unescape_string(data)
    end
    return data
end

read_stringnl_noescape(io::IO) = read_stringnl(io, stripquotes=false)

"""
# Examples
```jldoctest
julia> using Pickle

julia> Pickle.read_stringnl_noescape_pair(IOBuffer(b"Queue\nEmpty\njunk"))
"Queue Empty"
```
"""
read_stringnl_noescape_pair(io::IO) = "$(read_stringnl_noescape(io)) $(read_stringnl_noescape(io))"

function read_multiple(io::IO, name::String, nf::Function)
    n = nf(io)
    data = read(io, n)
    length(data) != n && error("expected $n bytes in $name, but only $(length(data)) remain")
    return data
end
read_multiple(io::IO, T::Type, name::String, nf::Function) = T(read_multiple(io, name, nf))

"""
# Examples
```jldoctest
julia> using Pickle

julia> Pickle.read_string1(IOBuffer(b"\x00"))
""

julia> Pickle.read_string1(IOBuffer(b"\x03abcdef"))
"abc"
```
"""
read_string1(io::IO) = read_multiple(io, String, "string1", read_uint1)

"""
# Examples
```jldoctest
julia> using Pickle

julia> Pickle.read_string4(IOBuffer(b"\x00\x00\x00\x00abc"))
""

julia> Pickle.read_string4(IOBuffer(b"\x03\x00\x00\x00abcdef"))
"abc"

julia> Pickle.read_string4(IOBuffer(b"\x00\x00\x00\x03abcdef"))
ERROR: expected 50331648 bytes in string4, but only 6 remain
Stacktrace:
 [1] error(::String) at ./error.jl:33
 [2] read_multiple(::Base.GenericIOBuffer{Base.CodeUnits{UInt8,String}}, ::String, ::typeof(Pickle.read_int4)) at /media/yuehhua/Workbench/workspace/Pickle.jl/src/readarg.jl:139
 [3] read_multiple at /media/yuehhua/Workbench/workspace/Pickle.jl/src/readarg.jl:142 [inlined]
 [4] read_string4(::Base.GenericIOBuffer{Base.CodeUnits{UInt8,String}}) at /media/yuehhua/Workbench/workspace/Pickle.jl/src/readarg.jl:154
 [5] top-level scope at REPL[6]:1
```
"""
read_string4(io::IO) = read_multiple(io, String, "string4", read_int4)

"""
# Examples
```jldoctest
julia> using Pickle

julia> Pickle.read_bytes1(IOBuffer(b"\x00"))
0-element Array{UInt8,1}

julia> Pickle.read_bytes1(IOBuffer(b"\x03abcdef"))
3-element Array{UInt8,1}:
 0x61
 0x62
 0x63

julia> Pickle.read_bytes1(IOBuffer(b"\x03abcdef")) |> String
"abc"
```
"""
read_bytes1(io::IO) = read_multiple(io, "bytes1", read_uint1)

"""
# Examples
```jldoctest
julia> using Pickle

julia> Pickle.read_bytes4(IOBuffer(b"\x00\x00\x00\x00abc"))
0-element Array{UInt8,1}

julia> Pickle.read_bytes4(IOBuffer(b"\x03\x00\x00\x00abcdef"))
3-element Array{UInt8,1}:
 0x61
 0x62
 0x63

julia> Pickle.read_bytes4(IOBuffer(b"\x00\x00\x00\x03abcdef"))
ERROR: expected 50331648 bytes in bytes4, but only 6 remain
Stacktrace:
 [1] error(::String) at ./error.jl:33
 [2] read_multiple(::Base.GenericIOBuffer{Base.CodeUnits{UInt8,String}}, ::String, ::typeof(Pickle.read_uint4)) at /media/yuehhua/Workbench/workspace/Pickle.jl/src/readarg.jl:139
 [3] read_bytes4(::Base.GenericIOBuffer{Base.CodeUnits{UInt8,String}}) at /media/yuehhua/Workbench/workspace/Pickle.jl/src/readarg.jl:157
 [4] top-level scope at REPL[12]:1
```
"""
read_bytes4(io::IO) = read_multiple(io, "bytes4", read_uint4)

"""
# Examples
```jldoctest
julia> using Pickle

julia> Pickle.read_bytes8(IOBuffer(b"\x00\x00\x00\x00\x00\x00\x00\x00abc"))
0-element Array{UInt8,1}

julia> Pickle.read_bytes8(IOBuffer(b"\x03\x00\x00\x00\x00\x00\x00\x00abcdef"))
3-element Array{UInt8,1}:
 0x61
 0x62
 0x63
```
"""
read_bytes8(io::IO) = read_multiple(io, "bytes8", read_uint8)



########################
# this function only make sense in python.

"""
# Examples
```jldoctest
julia> using Pickle

julia> Pickle.read_bytearray8(IOBuffer(b"\x00\x00\x00\x00\x00\x00\x00\x00abc"))
0-element Array{UInt8,1}

julia> Pickle.read_bytearray8(IOBuffer(b"\x03\x00\x00\x00\x00\x00\x00\x00abcdef"))
3-element Array{UInt8,1}:
 0x61
 0x62
 0x63
```
"""
read_bytearray8(io::IO) = read_multiple(io, "bytearray8", read_uint8)

"""
# Examples
```jldoctest
julia> using Pickle

julia> Pickle.read_unicodestringnl(IOBuffer(b"abc\\uabcd\njunk")) == "abc\uabcd"
true
```
"""
function read_unicodestringnl(io::IO)
    data = readline(io; keep=true)
    data[end] != '\n' && error("no newline found when trying to read unicodestringnl")
    data = data[1:end-1]
    return unescape_string(data)
end

read_unicodestring1(io::IO)  = read_multiple(io, String, "unicodestring1", read_uint1)
read_unicodestring4(io::IO)  = read_multiple(io, String, "unicodestring4", read_int4)
read_unicodestring8(io::IO)  = read_multiple(io, String, "unicodestring8", read_uint8)
########################

function parseint(s; base=10)
    i = tryparse(Int, s; base=base)
    !isnothing(i) && return i
    bi = tryparse(BigInt, s; base=base)
    !isnothing(bi) && return bi
    return nothing
end

"""
# Examples
```jldoctest
julia> using Pickle

julia> Pickle.read_decimalnl_short(IOBuffer(b"1234\n56"))
1234

julia> Pickle.read_decimalnl_short(IOBuffer(b"1234L\n56"))
ERROR: invalid literal for Integer with base 10: 1234L
Stacktrace:
 [1] error(::String) at ./error.jl:33
 [2] read_decimalnl_short(::Base.GenericIOBuffer{Base.CodeUnits{UInt8,String}}) at /media/yuehhua/Workbench/workspace/Pickle.jl/src/readarg.jl:196
 [3] top-level scope at REPL[40]:1
```
"""
function read_decimalnl_short(io::IO)
    s = read_stringnl(io, decode=false, stripquotes=false)

    if isequal("00")(s)
        return false
    elseif isequal("01")(s)
        return true
    end

    int = parseint(s)
    isnothing(int) &&
        error("invalid literal for Integer with base 10: $s")
    return int
end

"""
# Examples
```jldoctest
julia> using Pickle

julia> Pickle.read_decimalnl_long(IOBuffer(b"1234L\n56"))
1234

julia> Pickle.read_decimalnl_long(IOBuffer(b"123456789012345678901234L\n6"))
123456789012345678901234
```
"""
function read_decimalnl_long(io::IO)
    s = read_stringnl(io, decode=false, stripquotes=false)
    if s[end] == 'L'
        s = s[1:end-1]
    end

    int = parseint(s)
    isnothing(int) &&
        error("invalid literal for Integer with base 10: $s")
    return int
end

"""
# Examples
```jldoctest
julia> using Pickle

julia> Pickle.read_floatnl(IOBuffer(b"-1.25\n6"))
-1.25
```
"""
function read_floatnl(io::IO)
    s = read_stringnl(io, decode=false, stripquotes=false)
    return parse(Float64, s)
end

"""
# Examples
```jldoctest
julia> using Pickle

julia> Pickle.read_float8(IOBuffer(b"\xbf\xf4\x00\x00\x00\x00\x00\x00\n"))
-1.25
```
"""
read_float8(io::IO) = bswap(read(io, Float64))

function int_from_bytes(x)
    isempty(x) && return 0
    islittle = Base.ENDIAN_BOM == 0x04030201
    islittle && (x = reverse(x))
    isneg = isone(first(x) >> 7)
    if !isneg
        s = Base.bytes2hex(x)
        i = parseint(s; base=16)
        isnothing(i) && error("2's complement bytes parse error")
        return i
    else
        s = Base.bytes2hex(x .⊻ 0xff)
        i = parseint(s; base=16)
        isnothing(i) && error("2's complement bytes parse error")
        return -i-1
    end
end

read_long1(io::IO) = int_from_bytes(read_multiple(io, "bytes1", read_uint1))
read_long4(io::IO) = int_from_bytes(read_multiple(io, "bytes4", read_int4))

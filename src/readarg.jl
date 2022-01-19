@doc raw"""
read 1 byte as `UInt8` from `io`.

# Examples

```jldoctest
julia> Pickle.read_uint1(IOBuffer(b"\xff"))
0xff

```
"""
read_uint1(io::IO) = read(io, UInt8)

@doc raw"""
read 2 bytes as `UInt16` from `io`.

# Examples
```jldoctest
julia> Pickle.read_uint2(IOBuffer(b"\xff\x00"))
0x00ff

julia> Pickle.read_uint2(IOBuffer(b"\xff\xff"))
0xffff
```
"""
read_uint2(io::IO) = read(io, UInt16)

@doc raw"""
read 4 bytes as `Int32` from `io`.

# Examples
```jldoctest
julia> Pickle.read_int4(IOBuffer(b"\xff\x00\x00\x00"))
255

julia> Pickle.read_int4(IOBuffer(b"\x00\x00\x00\x80")) == -2^31
true
```
"""
read_int4(io::IO) = read(io, Int32)

@doc raw"""
read 4 bytes as `UInt32` from `io`.

# Examples
```jldoctest
julia> Pickle.read_uint4(IOBuffer(b"\xff\x00\x00\x00"))
0x000000ff

julia> Pickle.read_uint4(IOBuffer(b"\x00\x00\x00\x80")) == 2^31
true
```
"""
read_uint4(io::IO) = read(io, UInt32)

@doc raw"""
read 8 bytes as `UInt64` from `io`.

# Examples
```jldoctest
julia> Pickle.read_uint8(IOBuffer(b"\xff\x00\x00\x00\x00\x00\x00\x00"))
0x00000000000000ff

julia> Pickle.read_uint8(IOBuffer(b"\xff\xff\xff\xff\xff\xff\xff\xff")) == UInt64(2^64) - UInt64(1)
true
```
"""
read_uint8(io::IO) = read(io, UInt64)

@doc raw"""
read a string with quotes end with "\n" (newline) from `io`.

# Examples
```jldoctest
julia> Pickle.read_stringnl(IOBuffer(b"'abcdé'\nefg\n"))
"abcdé"

julia> Pickle.read_stringnl(IOBuffer(b"\n"))
ERROR: no string quotes around
[...]

julia> Pickle.read_stringnl(IOBuffer(b"\n"), stripquotes=false)
""

julia> Pickle.read_stringnl(IOBuffer(b"''\n"))
""

julia> Pickle.read_stringnl(IOBuffer(b"\\"abcd\\""))
ERROR: no newline found when trying to read stringnl
[...]
```
"""
function read_stringnl(io::IO; decode=true, stripquotes=true)
    data = readline(io; keep=true)
    data[end] != '\n' && error("no newline found when trying to read stringnl")

    if endswith(data, "\r\n") # handle windows newline
        nl_idx = lastindex(data) - 1
    else
        nl_idx = lastindex(data)
    end

    if stripquotes
        isquote(c) = isequal('\'')(c) || isequal('\"')(c)
        start = first(data)
        !isquote(start) && error("no string quotes around $data")

        endl = data[prevind(data, nl_idx)]
        !isequal(start, endl) && error("string quote $start not found at both end of $data")

        data = data[2:prevind(data, nl_idx-1)]
    else
        data = data[1:prevind(data, nl_idx)]
    end

    if decode
        return unescape_string(data)
    end
    return data
end

read_stringnl_noescape(io::IO) = read_stringnl(io, stripquotes=false)

@doc raw"""
read a pair of unescape string from `io`.

# Examples
```jldoctest
julia> Pickle.read_stringnl_noescape_pair(IOBuffer(b"Queue\nEmpty\njunk"))
("Queue", "Empty")
```
"""
read_stringnl_noescape_pair(io::IO) = (read_stringnl_noescape(io), read_stringnl_noescape(io))

function read_multiple(io::IO, name::String, nf::Function)
    n = nf(io)
    data = read(io, n)
    length(data) != n && error("expected $n bytes in $name, but only $(length(data)) remain")
    return data
end
read_multiple(io::IO, T::Type, name::String, nf::Function) = T(read_multiple(io, name, nf))

@doc raw"""
read 1 byte as `UInt8` for length n and read n bytes as `String` from `io`.`

# Examples
```jldoctest
julia> Pickle.read_string1(IOBuffer(b"\x00"))
""

julia> Pickle.read_string1(IOBuffer(b"\x03abcdef"))
"abc"
```
"""
read_string1(io::IO) = read_multiple(io, String, "string1", read_uint1)

@doc raw"""
# Examples
```jldoctest
julia> Pickle.read_string4(IOBuffer(b"\x00\x00\x00\x00abc"))
""

julia> Pickle.read_string4(IOBuffer(b"\x03\x00\x00\x00abcdef"))
"abc"

julia> Pickle.read_string4(IOBuffer(b"\x00\x00\x00\x03abcdef"))
ERROR: expected 50331648 bytes in string4, but only 6 remain
[...]
```
"""
read_string4(io::IO) = read_multiple(io, String, "string4", read_int4)

@doc raw"""
# Examples
```jldoctest
julia> Pickle.read_bytes1(IOBuffer(b"\x00")) |> isempty # 0-element Vector{UInt8}
true

julia> Pickle.read_bytes1(IOBuffer(b"\x03abcdef"))
3-element Vector{UInt8}:
 0x61
 0x62
 0x63

julia> Pickle.read_bytes1(IOBuffer(b"\x03abcdef")) |> String
"abc"
```
"""
read_bytes1(io::IO) = read_multiple(io, "bytes1", read_uint1)

@doc raw"""
# Examples
```jldoctest
julia> Pickle.read_bytes4(IOBuffer(b"\x00\x00\x00\x00abc")) |> isempty # 0-element Vector{UInt8}
true

julia> Pickle.read_bytes4(IOBuffer(b"\x03\x00\x00\x00abcdef"))
3-element Vector{UInt8}:
 0x61
 0x62
 0x63

julia> Pickle.read_bytes4(IOBuffer(b"\x00\x00\x00\x03abcdef"))
ERROR: expected 50331648 bytes in bytes4, but only 6 remain
[...]
```
"""
read_bytes4(io::IO) = read_multiple(io, "bytes4", read_uint4)

@doc raw"""
# Examples
```jldoctest
julia> Pickle.read_bytes8(IOBuffer(b"\x00\x00\x00\x00\x00\x00\x00\x00abc")) |> isempty # 0-element Vector{UInt8}
true

julia> Pickle.read_bytes8(IOBuffer(b"\x03\x00\x00\x00\x00\x00\x00\x00abcdef"))
3-element Vector{UInt8}:
 0x61
 0x62
 0x63
```
"""
read_bytes8(io::IO) = read_multiple(io, "bytes8", read_uint8)



########################
# this function only make sense in python.

@doc raw"""
# Examples
```jldoctest
julia> Pickle.read_bytearray8(IOBuffer(b"\x00\x00\x00\x00\x00\x00\x00\x00abc")) |> isempty # 0-element Vector{UInt8}
true

julia> Pickle.read_bytearray8(IOBuffer(b"\x03\x00\x00\x00\x00\x00\x00\x00abcdef"))
3-element Vector{UInt8}:
 0x61
 0x62
 0x63
```
"""
read_bytearray8(io::IO) = read_multiple(io, "bytearray8", read_uint8)

@doc raw"""
# Examples
```jldoctest
julia> Pickle.read_unicodestringnl(IOBuffer(b"abc\\uabcd\xe9\njunk")) == "abc\uabcdé"
true
```
"""
function read_unicodestringnl(io::IO)
    # handling raw-unicode-escape (latin1 with \u, \U)
    data = readuntil(io, 0x0a; keep=true)::Vector{UInt8}
    data = decode(data, "latin1")
    data[end] != '\n' && error("no newline found when trying to read unicodestringnl")

    if endswith(data, "\r\n") # handle windows newline
        nl_idx = lastindex(data) - 1
    else
        nl_idx = lastindex(data)
    end

    data = data[1:prevind(data, nl_idx)]
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

@doc raw"""
# Examples
```jldoctest
julia> Pickle.read_decimalnl_short(IOBuffer(b"1234\n56"))
1234

julia> Pickle.read_decimalnl_short(IOBuffer(b"1234L\n56"))
ERROR: invalid literal for Integer with base 10: 1234L
[...]
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

@doc raw"""
# Examples
```jldoctest
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

@doc raw"""
# Examples
```jldoctest
julia> Pickle.read_floatnl(IOBuffer(b"-1.25\n6"))
-1.25
```
"""
function read_floatnl(io::IO)
    s = read_stringnl(io, decode=false, stripquotes=false)
    return parse(Float64, s)
end

@doc raw"""
# Examples
```jldoctest
julia> Pickle.read_float8(IOBuffer(b"\xbf\xf4\x00\x00\x00\x00\x00\x00\n"))
-1.25
```
"""
read_float8(io::IO) = bswap(read(io, Float64))

@doc raw"""
convert a 2's complement byte array (Vector{UInt8}) into Signed Integer.

# Examples
```jldoctest
julia> Pickle.int_from_bytes(b"")
0

julia> Pickle.int_from_bytes(b"\xff\x00")
255

julia> Pickle.int_from_bytes(b"\xff\x7f")
32767

julia> Pickle.int_from_bytes(b"\x00\xff")
-256

julia> Pickle.int_from_bytes(b"\x00\x80")
-32768

julia> Pickle.int_from_bytes(b"\x80")
-128

julia> Pickle.int_from_bytes(b"\x7f")
127
```
"""
function int_from_bytes(x)
    isempty(x) && return 0
    islittle_endian() && (x = reverse(x))
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

@doc raw"""
# Examples
```jldoctest
julia> Pickle.read_long1(IOBuffer(b"\x00"))
0

julia> Pickle.read_long1(IOBuffer(b"\x02\xff\x00"))
255

julia> Pickle.read_long1(IOBuffer(b"\x02\xff\x7f"))
32767

julia> Pickle.read_long1(IOBuffer(b"\x02\x00\xff"))
-256

julia> Pickle.read_long1(IOBuffer(b"\x02\x00\x80"))
-32768
```
"""
read_long1(io::IO) = int_from_bytes(read_multiple(io, "bytes1", read_uint1))

@doc raw"""
# Examples
```jldoctest
julia> Pickle.read_long4(IOBuffer(b"\x02\x00\x00\x00\xff\x00"))
255

julia> Pickle.read_long4(IOBuffer(b"\x02\x00\x00\x00\xff\x7f"))
32767

julia> Pickle.read_long4(IOBuffer(b"\x02\x00\x00\x00\x00\xff"))
-256

julia> Pickle.read_long4(IOBuffer(b"\x02\x00\x00\x00\x00\x80"))
-32768

julia> Pickle.read_long4(IOBuffer(b"\x00\x00\x00\x00"))
0
```
"""
read_long4(io::IO) = int_from_bytes(read_multiple(io, "bytes4", read_int4))

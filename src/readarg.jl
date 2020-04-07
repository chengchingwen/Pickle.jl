read_uint1(io::IO) = read(io, UInt8)
read_uint2(io::IO) = read(io, UInt16)
read_int4(io::IO) = read(io, Int32)
read_uint4(io::IO) = read(io, UInt32)
read_uint8(io::IO) = read(io, UInt64)

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
read_stringnl_noescape_pair(io::IO) = "$(read_stringnl_noescape(io)) $(read_stringnl_noescape(io))"

function read_multiple(io::IO, name::String, nf::Function)
    n = nf(io)
    data = read(io, n)
    length(data) != n && error("expected $n bytes in $name, but only $(length(data)) remain")
    return data
end
read_multiple(io::IO, T::Type, name::String, nf::Function) = T(read_multiple(io, name, nf))

read_string1(io::IO) = read_multiple(io, String, "string1", read_uint1)
read_string4(io::IO) = read_multiple(io, String, "string4", read_int4)

read_bytes1(io::IO) = read_multiple(io, "bytes1", read_uint1)
read_bytes4(io::IO) = read_multiple(io, "bytes4", read_uint4)
read_bytes8(io::IO) = read_multiple(io, "bytes8", read_uint8)



########################
# this function only make sense in python.

read_bytearray8(io::IO) = read_multiple(io, "bytearray8", read_uint8)
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

function read_floatnl(io::IO)
    s = read_stringnl(io, decode=false, stripquotes=false)
    return parse(Float64, s)
end

read_float8(io::IO) = bswap(read(io, Float64))

function int_from_bytes(x)
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

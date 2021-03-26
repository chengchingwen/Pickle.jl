"write 1 byte as `UInt8` to `io`"
write_uint1(io::IO, arg) = write(io, UInt8(arg))

"write 2 bytes as `UInt16` to `io`"
write_uint2(io::IO, arg) = write(io, UInt16(arg))

"write 4 bytes as `Int32` to `io`"
write_int4(io::IO, arg) = write(io, Int32(arg))

"write 4 bytes as `UInt32` to `io`"
write_uint4(io::IO, arg) = write(io, UInt32(arg))

"write 8 bytes as `UInt64` to `io`"
write_uint8(io::IO, arg) = write(io, UInt64(arg))

@doc raw"""
write unicode string as plain ascii string to `io`

# Examples
```jldoctest
julia> sprint(Pickle.write_plain_str, "abcα😀")
"abc\\u03b1\\U0001f600"
```
"""
function write_plain_str(io::IO, arg)
  len = 0
  for c in arg
    if isascii(c)
      if c == '\\'
        len += write(io, "\\u005c")
      elseif c == '\0'
        len += write(io, "\\u0000")
      elseif c == '\n'
        len += write(io, "\\u000a")
      elseif c == '\r'
        len += write(io, "\\u000d")
      elseif c == '\u1a'
        len += write(io, "\\u001a")
      else
        len += write(io, c)
      end
    else
      if codepoint(c) >> 16 |> !iszero # large unicode
        len += write(io, "\\U")
        len += write(io, lpad(string(codepoint(c); base=16), 8, '0'))
      else
        len += write(io, "\\u")
        len += write(io, lpad(string(codepoint(c); base=16), 4, '0'))
      end
    end
  end
  len
end

"""
convert a Integer into 2's complement byte array (Vector{UInt8}).

# Examples
```jldoctest
julia> Pickle.int_to_bytes(0) |> isempty # 0-element Vector{UInt8}
true

julia> Pickle.int_to_bytes(255)
2-element Vector{UInt8}:
 0xff
 0x00

julia> Pickle.int_to_bytes(32767)
2-element Vector{UInt8}:
 0xff
 0x7f

julia> Pickle.int_to_bytes(-256)
2-element Vector{UInt8}:
 0x00
 0xff

julia> Pickle.int_to_bytes(-32768)
2-element Vector{UInt8}:
 0x00
 0x80

julia> Pickle.int_to_bytes(-128)
1-element Vector{UInt8}:
 0x80

julia> Pickle.int_to_bytes(127)
1-element Vector{UInt8}:
 0x7f
```
"""
function int_to_bytes(x)
  iszero(x) && return Vector{UInt8}()
  islittle = Base.ENDIAN_BOM == 0x04030201
  isneg = x < 0

  if isneg
    x += 1
  end

  hexstr = x > 0 ? string(x; base=16) : string(-x; base=16)
  if length(hexstr) |> isodd
    hexstr = lpad(hexstr, length(hexstr)+1, '0')
  else
    if !(first(hexstr) < '8')
      hexstr = lpad(hexstr, length(hexstr)+2, '0')
    end
  end

  bytes = hex2bytes(hexstr)
  islittle && (bytes = reverse(bytes))

  if isneg
    bytes .⊻= 0xff
  end

  return bytes
end

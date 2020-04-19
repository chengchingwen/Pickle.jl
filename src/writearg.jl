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

"""
write unicode string as plain ascii string to `io`

# Examples
```jldoctest
julia> sprint(Pickle.write_plain_str, "abcα😀")
"abc\\\\u03b1\\\\U0001f600"
```
"""
function write_plain_str(io::IO, arg)
  for c in arg
    if isascii(c)
      if c == '\\'
        write(io, "\\u005c")
      elseif c == '\0'
        write(io, "\\u0000")
      elseif c == '\n'
        write(io, "\\u000a")
      elseif c == '\r'
        write(io, "\\u000d")
      elseif c == '\u1a'
        write(io, "\\u001a")
      else
        write(io, c)
      end
    else
      if codepoint(c) >> 16 |> !iszero # large unicode
        write(io, "\\U")
        write(io, lpad(string(codepoint(c); base=16), 8, '0'))
      else
        write(io, "\\u")
        write(io, lpad(string(codepoint(c); base=16), 4, '0'))
      end
    end
  end
  io
end

"""
convert a Integer into 2's complement byte array (Vector{UInt8}).

# Examples
```jldoctest
julia> Pickle.int_to_bytes(0)
0-element Array{UInt8,1}

julia> Pickle.int_to_bytes(255)
2-element Array{UInt8,1}:
 0xff
 0x00

julia> Pickle.int_to_bytes(32767)
2-element Array{UInt8,1}:
 0xff
 0x7f

julia> Pickle.int_to_bytes(-256)
2-element Array{UInt8,1}:
 0x00
 0xff

julia> Pickle.int_to_bytes(-32768)
2-element Array{UInt8,1}:
 0x00
 0x80

julia> Pickle.int_to_bytes(-128)
1-element Array{UInt8,1}:
 0x80

julia> Pickle.int_to_bytes(127)
1-element Array{UInt8,1}:
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

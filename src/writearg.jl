write_uint1(io::IO, arg) = write(io, UInt8(arg))
write_uint2(io::IO, arg) = write(io, UInt16(arg))
write_int4(io::IO, arg) = write(io, Int32(arg))
write_uint4(io::IO, arg) = write(io, UInt32(arg))
write_uint8(io::IO, arg) = write(io, UInt64(arg))

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


function int_to_bytes(x)
  iszero(x) && return b""
  islittle = Base.ENDIAN_BOM == 0x04030201
  isneg = x < 0

  if isneg
    x += 1
  end

  hexstr = x > 0 ? string(x; base=16) : string(-x; base=16)
  if length(hexstr) |> isodd
    hexstr = lpad(hexstr, length(hexstr)+1, '0')
  end

  bytes = hex2bytes(hexstr)
  islittle && (bytes = reverse(bytes))

  if isneg
    bytes .⊻= 0xff
  end

  return bytes
end

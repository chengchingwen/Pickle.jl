module OpCodes

using ..Pickle

export OpCode, genops

using Base.Enums: namemap

@enum OpCode::UInt8 begin
    # integers
    INT                = codepoint('I')
    BININT             = codepoint('J')
    BININT1            = codepoint('K')
    BININT2            = codepoint('M')
    LONG               = codepoint('L')
    LONG1              = 0x8a
    LONG4              = 0x8b
    # strings
    STRING             = codepoint('S')
    BINSTRING          = codepoint('T')
    SHORT_BINSTRING    = codepoint('U')
    # bytes (protocal 3 and higher)
    BINBYTES           = codepoint('B')
    SHORT_BINBYTES     = codepoint('C')
    BINBYTES8          = 0x8e
    # bytearray (protocal 5 and higher)
    BYTEARRAY8         = 0x96
    # out-of-band buffer (protocol 5 and higher)
    NEXT_BUFFER        = 0x97
    READONLY_BUFFER    = 0x98
    # none
    NONE               = codepoint('N')
    # bool (protocal 2 and higher)
    NEWTRUE            = 0x88
    NEWFALSE           = 0x89
    # unicode string
    UNICODE            = codepoint('V')
    SHORT_BINUNICODE   = 0x8c
    BINUNICODE         = codepoint('X')
    BINUNICODE8        = 0x8d
    # floats
    FLOAT              = codepoint('F')
    BINFLOAT           = codepoint('G')
    # build list
    EMPTY_LIST         = codepoint(']')
    APPEND             = codepoint('a')
    APPENDS            = codepoint('e')
    LIST               = codepoint('l')
    # build tuples
    EMPTY_TUPLE        = codepoint(')')
    TUPLE              = codepoint('t')
    TUPLE1             = 0x85
    TUPLE2             = 0x86
    TUPLE3             = 0x87
    # build dicts
    EMPTY_DICT         = codepoint('}')
    DICT               = codepoint('d')
    SETITEM            = codepoint('s')
    SETITEMS           = codepoint('u')
    # build sets
    EMPTY_SET          = 0x8f
    ADDITEMS           = 0x90
    # build frozensets
    FROZENSET          = 0x91
    # stack manipulation
    POP                = codepoint('0')
    DUP                = codepoint('2')
    MARK               = codepoint('(')
    POP_MARK           = codepoint('1')
    # memo manipulation
    GET                = codepoint('g')
    BINGET             = codepoint('h')
    LONG_BINGET        = codepoint('j')
    PUT                = codepoint('p')
    BINPUT             = codepoint('q')
    LONG_BINPUT        = codepoint('r')
    MEMOIZE            = 0x94
    # extension registry
    EXT1               = 0x82
    EXT2               = 0x83
    EXT4               = 0x84
    # push class or function to stack by module and name
    GLOBAL             = codepoint('c')
    STACK_GLOBAL       = 0x93
    # build unknown objects
    REDUCE             = codepoint('R')
    BUILD              = codepoint('b')
    INST               = codepoint('i')
    OBJ                = codepoint('o')
    NEWOBJ             = 0x81
    NEWOBJ_EX          = 0x92
    # machine control
    PROTO              = 0x80
    STOP               = codepoint('.')
    # Framing support
    FRAME              = 0x95
    # persistent IDs
    PERSID             = codepoint('P')
    BINPERSID          = codepoint('Q')
end

"""
  `OpCode`s of Pickle stack machine.
"""
OpCode

include("./opcode_desc.jl")

"""
    argument(::OpCode)

return the argument reader of an OpCode.
"""
argument(op::OpCode) = argument(Val(op))


for (ops, f) in (
  :(INT, GET, PUT,)            => :read_decimalnl_short,
  :(LONG,)                     => :read_decimalnl_long,
  :(BININT, EXT4,)             => :read_int4,
  :(BININT1, BINGET, BINPUT,
    EXT1, PROTO,)              => :read_uint1,
  :(BININT2, EXT2,)            => :read_uint2,
  :(LONG_BINGET, LONG_BINPUT,) => :read_uint4,
  :(FRAME,)                    => :read_uint8,
  :(LONG1,)                    => :read_long1,
  :(LONG4,)                    => :read_long4,
  :(STRING,)                   => :read_stringnl,
  :(SHORT_BINSTRING,)          => :read_string1,
  :(BINSTRING,)                => :read_string4,
  :(SHORT_BINBYTES,)           => :read_bytes1,
  :(BINBYTES,)                 => :read_bytes4,
  :(BINBYTES8,)                => :read_bytes8,
  :(BYTEARRAY8,)               => :read_bytearray8,
  :(UNICODE,)                  => :read_unicodestringnl,
  :(SHORT_BINUNICODE,)         => :read_unicodestring1,
  :(BINUNICODE,)               => :read_unicodestring4,
  :(BINUNICODE8,)              => :read_unicodestring8,
  :(FLOAT,)                    => :read_floatnl,
  :(BINFLOAT,)                 => :read_float8,
  :(PERSID,)                   => :read_stringnl_noescape,
  :(GLOBAL, INST,)             => :read_stringnl_noescape_pair,
  :(NEXT_BUFFER, READONLY_BUFFER,
    NONE, NEWTRUE, NEWFALSE,
    EMPTY_LIST, APPEND, APPENDS, LIST,
    EMPTY_TUPLE, TUPLE, TUPLE1, TUPLE2, TUPLE3,
    EMPTY_DICT, DICT, SETITEM, SETITEMS,
    EMPTY_SET, ADDITEMS, FROZENSET,
    POP, DUP, MARK, POP_MARK, MEMOIZE,
    STACK_GLOBAL, REDUCE, BUILD,
    OBJ, NEWOBJ, NEWOBJ_EX,
    STOP, BINPERSID,)          => nothing,
)
  if isnothing(f)
    for op in ops.args
      @eval argument(::Val{$op}) = nothing
    end
  else
    for op in ops.args
      @eval argument(::Val{$op}) = Pickle.$f
    end
  end
end


function maybe_opcode(x)
    if x in keys(namemap(OpCode))
        return OpCode(x)
    end
    return nothing
end

"""
    genops(io::IO, yield_end_pos=false)

Generate/Dump all the opcode from pickle io.
"""
function genops(io::IO, yield_end_pos=false)
    Channel() do chn
        while !eof(io)
            pos = position(io)
            code = read(io, UInt8)
            opcode = maybe_opcode(code)
            isnothing(opcode) &&
                error("at position $pos, code $code unknown.")

            argf = argument(opcode)
            arg = isnothing(argf) ? nothing : argf(io)
            if yield_end_pos
                put!(chn, (opcode, arg, pos, position(io)))
            else
                put!(chn, (opcode, arg, pos))
            end
            isequal(STOP)(opcode) && break
        end
    end
end

end

module OpCodes

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
argument(::Val{INT}) = read_decimalnl_short
argument(::Val{BININT}) = read_int4
argument(::Val{BININT1}) = read_uint1
argument(::Val{BININT2}) = read_uint2
argument(::Val{LONG}) = read_decimalnl_long
argument(::Val{LONG1}) = read_long1
argument(::Val{LONG4}) = read_long4
argument(::Val{STRING}) = read_stringnl
argument(::Val{BINSTRING}) = read_string4
argument(::Val{SHORT_BINSTRING}) = read_string1
argument(::Val{BINBYTES}) = read_bytes4
argument(::Val{SHORT_BINBYTES}) = read_bytes1
argument(::Val{BINBYTES8}) = read_bytes8
argument(::Val{BYTEARRAY8}) = read_bytearray8
argument(::Val{NEXT_BUFFER}) = nothing
argument(::Val{READONLY_BUFFER}) = nothing
argument(::Val{NONE}) = nothing
argument(::Val{NEWTRUE}) = nothing
argument(::Val{NEWFALSE}) = nothing
argument(::Val{UNICODE}) = read_unicodestringnl
argument(::Val{SHORT_BINUNICODE}) = read_unicodestring1
argument(::Val{BINUNICODE}) = read_unicodestring4
argument(::Val{BINUNICODE8}) = read_unicodestring8
argument(::Val{FLOAT}) = read_floatnl
argument(::Val{BINFLOAT}) = read_float8
argument(::Val{EMPTY_LIST}) = nothing
argument(::Val{APPEND}) = nothing
argument(::Val{APPENDS}) = nothing
argument(::Val{LIST}) = nothing
argument(::Val{EMPTY_TUPLE}) = nothing
argument(::Val{TUPLE}) = nothing
argument(::Val{TUPLE1}) = nothing
argument(::Val{TUPLE2}) = nothing
argument(::Val{TUPLE3}) = nothing
argument(::Val{EMPTY_DICT}) = nothing
argument(::Val{DICT}) = nothing
argument(::Val{SETITEM}) = nothing
argument(::Val{SETITEMS}) = nothing
argument(::Val{EMPTY_SET}) = nothing
argument(::Val{ADDITEMS}) = nothing
argument(::Val{FROZENSET}) = nothing
argument(::Val{POP}) = nothing
argument(::Val{DUP}) = nothing
argument(::Val{MARK}) = nothing
argument(::Val{POP_MARK}) = nothing
argument(::Val{GET}) = read_decimalnl_short
argument(::Val{BINGET}) = read_uint1
argument(::Val{LONG_BINGET}) = read_uint4
argument(::Val{PUT}) = read_decimalnl_short
argument(::Val{BINPUT}) = read_uint1
argument(::Val{LONG_BINPUT}) = read_uint4
argument(::Val{MEMOIZE}) = nothing
argument(::Val{EXT1}) = read_uint1
argument(::Val{EXT2}) = read_uint2
argument(::Val{EXT4}) = read_int4
argument(::Val{GLOBAL}) = read_stringnl_noescape_pair
argument(::Val{STACK_GLOBAL}) = nothing
argument(::Val{REDUCE}) = nothing
argument(::Val{BUILD}) = nothing
argument(::Val{INST}) = read_stringnl_noescape_pair
argument(::Val{OBJ}) = nothing
argument(::Val{NEWOBJ}) = nothing
argument(::Val{NEWOBJ_EX}) = nothing
argument(::Val{PROTO}) = read_uint1
argument(::Val{STOP}) = nothing
argument(::Val{FRAME}) = read_uint8
argument(::Val{PERSID}) = read_stringnl_noescape
argument(::Val{BINPERSID}) = nothing

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

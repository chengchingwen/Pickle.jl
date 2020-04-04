using Base.Enums: namemap

@enum OpCode::UInt8 begin
    # integers
    int                = codepoint('I')
    binint             = codepoint('J')
    binint1            = codepoint('K')
    binint2            = codepoint('M')
    long               = codepoint('L')
    long1              = 0x8a
    long4              = 0x8b
    # strings
    string             = codepoint('S')
    binstring          = codepoint('T')
    short_binstring    = codepoint('U')
    # bytes (protocal 3 and higher)
    binbytes           = codepoint('B')
    short_binbytes     = codepoint('C')
    binbytes8          = 0x8e
    # bytearray (protocal 5 and higher)
    bytearray8         = 0x96
    # out-of-band buffer (protocol 5 and higher)
    next_buffer        = 0x97
    readonly_buffer    = 0x98
    # none
    none               = codepoint('N')
    # bool (protocal 2 and higher)
    newtrue            = 0x88
    newfalse           = 0x89
    # unicode string
    unicode            = codepoint('V')
    short_binunicode   = 0x8c
    binunicode         = codepoint('X')
    binunicode8        = 0x8d
    # floats
    float              = codepoint('F')
    binfloat           = codepoint('G')
    # build list
    empty_list         = codepoint(']')
    append             = codepoint('a')
    appends            = codepoint('e')
    list               = codepoint('l')
    # build tuples
    empty_tuple        = codepoint(')')
    tuple              = codepoint('t')
    tuple1             = 0x85
    tuple2             = 0x86
    tuple3             = 0x87
    # build dicts
    empty_dict         = codepoint('}')
    dict               = codepoint('d')
    setitem            = codepoint('s')
    setitems           = codepoint('u')
    # build sets
    empty_set          = 0x8f
    additems           = 0x90
    # build frozensets
    frozenset          = 0x91
    # stack manipulation
    pop                = codepoint('0')
    dup                = codepoint('2')
    mark               = codepoint('(')
    pop_mark           = codepoint('1')
    # memo manipulation
    get                = codepoint('g')
    binget             = codepoint('h')
    long_binget        = codepoint('j')
    put                = codepoint('p')
    binput             = codepoint('q')
    long_binput        = codepoint('r')
    memoize            = 0x94
    # extension registry
    ext1               = 0x82
    ext2               = 0x83
    ext4               = 0x84
    # push class or function to stack by module and name
    Global             = codepoint('c')
    stack_Global       = 0x93
    # build unknown objects
    reduce             = codepoint('R')
    build              = codepoint('b')
    inst               = codepoint('i')
    obj                = codepoint('o')
    newobj             = 0x81
    newobj_ex          = 0x92
    # machine control
    proto              = 0x80
    stop               = codepoint('.')
    # Framing support
    frame              = 0x95
    # persistent IDs
    persid             = codepoint('P')
    binpersid          = codepoint('Q')
end

function maybe_opcode(x)
    if x in keys(namemap(OpCode))
        return OpCode(x)
    end
    return nothing
end

if VERSION < v"1.1"
    isnothing(::Nothing) = true
    isnothing(::Any) = false
end

function genops(io::IO, yield_end_pos=false)
    Channel() do chn
        while !eof(io)
            pos = position(io)
            code = read(io, UInt8)
            opcode = maybe_opcode(code)
            isnothing(opcode) &&
                error("at position $pos, code $code unknown.")

            arg = arguement(opcode)
            if yield_end_pos
                put!(chn, (opcode, arg, pos, position(io)))
            else
                put!(chn, (opcode, arg, pos))
            end
        end
    end
end

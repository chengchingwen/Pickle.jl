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

Docs.getdoc(op::OpCode) = Docs.getdoc(Val(op))
Docs.getdoc(::Val{INT}) = "push integer or bool"
Docs.getdoc(::Val{BININT}) = "push four-byte signed int"
Docs.getdoc(::Val{BININT1}) = "push 1-byte unsigned int"
Docs.getdoc(::Val{BININT2}) = "push 2-byte unsigned int"
Docs.getdoc(::Val{LONG}) = "push long"
Docs.getdoc(::Val{LONG1}) = "push long from < 256 bytes"
Docs.getdoc(::Val{LONG4}) = "push really big long"

Docs.getdoc(::Val{STRING}) = "push string; NL-terminated string argument"
Docs.getdoc(::Val{BINSTRING}) = "push string; counted binary string argument"
Docs.getdoc(::Val{SHORT_BINSTRING}) = "\"     \"   ;    \"      \"       \"      \" < 256 bytes"

Docs.getdoc(::Val{BINBYTES}) = "push bytes; counted binary string argument"
Docs.getdoc(::Val{SHORT_BINBYTES}) = "\"     \"   ;    \"      \"       \"      \" < 256 bytes"
Docs.getdoc(::Val{BINBYTES8}) = "push very long bytes string"

Docs.getdoc(::Val{BYTEARRAY8}) = "push bytearray"

Docs.getdoc(::Val{NEXT_BUFFER}) = "push next out-of-band buffer"
Docs.getdoc(::Val{READONLY_BUFFER}) = "make top of stack readonly"

Docs.getdoc(::Val{NONE}) = "push None"

Docs.getdoc(::Val{NEWTRUE}) = "push True"
Docs.getdoc(::Val{NEWFALSE}) = "push False"

Docs.getdoc(::Val{UNICODE}) = "push Unicode string; raw-unicode-escaped'd argument"
Docs.getdoc(::Val{SHORT_BINUNICODE}) = "push short string; UTF-8 length < 256 bytes"
Docs.getdoc(::Val{BINUNICODE}) = "  \"     \"       \"  ; counted UTF-8 string argument"
Docs.getdoc(::Val{BINUNICODE8}) = "push very long string"

Docs.getdoc(::Val{FLOAT}) = "push float object; decimal string argument"
Docs.getdoc(::Val{BINFLOAT}) = "push float; arg is 8-byte float encoding"

Docs.getdoc(::Val{EMPTY_LIST}) = "push empty list"
Docs.getdoc(::Val{APPEND}) = "append stack top to list below it"
Docs.getdoc(::Val{APPENDS}) = "extend list on stack by topmost stack slice"
Docs.getdoc(::Val{LIST}) = "build list from topmost stack items"

Docs.getdoc(::Val{EMPTY_TUPLE}) = "push empty tuple"
Docs.getdoc(::Val{TUPLE}) = "build tuple from topmost stack items"
Docs.getdoc(::Val{TUPLE1}) = "build 1-tuple from stack top"
Docs.getdoc(::Val{TUPLE2}) = "build 2-tuple from two topmost stack items"
Docs.getdoc(::Val{TUPLE3}) = "build 3-tuple from three topmost stack items"

Docs.getdoc(::Val{EMPTY_DICT}) = "push empty dict"
Docs.getdoc(::Val{DICT}) = "build a dict from stack items"
Docs.getdoc(::Val{SETITEM}) = "add key+value pair to dict"
Docs.getdoc(::Val{SETITEMS}) = "modify dict by adding topmost key+value pairs"

Docs.getdoc(::Val{EMPTY_SET}) = "push empty set on the stack"
Docs.getdoc(::Val{ADDITEMS}) = "modify set by adding topmost stack items"

Docs.getdoc(::Val{FROZENSET}) = "build frozenset from topmost stack items"

Docs.getdoc(::Val{POP}) = "discard topmost stack item"
Docs.getdoc(::Val{DUP}) = "duplicate top stack item"
Docs.getdoc(::Val{MARK}) = "push special markobject on stack"
Docs.getdoc(::Val{POP_MARK}) = "discard stack top through topmost markobject"

Docs.getdoc(::Val{GET}) = "push item from memo on stack; index is string arg"
Docs.getdoc(::Val{BINGET}) = "  \"    \"    \"    \"   \"   \"  ;   \"    \" 1-byte arg"
Docs.getdoc(::Val{LONG_BINGET}) = "push item from memo on stack; index is 4-byte arg"
Docs.getdoc(::Val{PUT}) = "store stack top in memo; index is string arg"
Docs.getdoc(::Val{BINPUT}) = "  \"     \"    \"   \"   \" ;   \"    \" 1-byte arg"
Docs.getdoc(::Val{LONG_BINPUT}) = "  \"     \"    \"   \"   \" ;   \"    \" 4-byte arg"
Docs.getdoc(::Val{MEMOIZE}) = "store top of the stack in memo"

Docs.getdoc(::Val{EXT1}) = "push object from extension registry; 1-byte index"
Docs.getdoc(::Val{EXT2}) = "push object from extension registry; 2-byte index"
Docs.getdoc(::Val{EXT4}) = "push object from extension registry; 4-byte index"

Docs.getdoc(::Val{GLOBAL}) = "push self.find_class(modname, name); 2 string args"
Docs.getdoc(::Val{STACK_GLOBAL}) = "same as GLOBAL but using names on the stacks"

Docs.getdoc(::Val{REDUCE}) = "apply callable to argtuple, both on stack"
Docs.getdoc(::Val{BUILD}) = "call __setstate__ or __dict__.update()"
Docs.getdoc(::Val{INST}) = "build & push class instance"
Docs.getdoc(::Val{OBJ}) = "build & push class instance"
Docs.getdoc(::Val{NEWOBJ}) = "build object by applying cls.__new__ to argtuple"
Docs.getdoc(::Val{NEWOBJ_EX}) = "like NEWOBJ but work with keyword only arguments"

Docs.getdoc(::Val{PROTO}) = "identify pickle protocol"
Docs.getdoc(::Val{STOP}) = "every pickle ends with STOP"

Docs.getdoc(::Val{FRAME}) = "indicate the beginning of a new frame"

Docs.getdoc(::Val{PERSID}) = "push persistent object; id is taken from string arg"
Docs.getdoc(::Val{BINPERSID}) = " \"       \"         \"  ;  \"  \"   \"     \"  stack"

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

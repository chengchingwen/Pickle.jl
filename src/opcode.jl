@enum OpCode begin
    # integers
    int                = Int('I')
    binint             = Int('J')
    binint1            = Int('K')
    binint2            = Int('M')
    long               = Int('L')
    long1              = 0x8a
    long4              = 0x8b
    # strings
    string             = Int('S')
    binstring          = Int('T')
    short_binstring    = Int('U')
    # bytes (protocal 3 and higher)
    binbytes           = Int('B')
    short_binbytes     = Int('C')
    binbytes8          = 0x8e
    # bytearray (protocal 5 and higher)
    bytearray8         = 0x96
    # out-of-band buffer (protocol 5 and higher)
    next_buffer        = 0x97
    readonly_buffer    = 0x98
    # none
    none               = Int('N')
    # bool (protocal 2 and higher)
    newtrue            = 0x88
    newfalse           = 0x89
    # unicode string
    unicode            = Int('V')
    short_binunicode   = 0x8c
    binunicode         = Int('X')
    binunicode8        = 0x8d
    # floats
    float              = Int('F')
    binfloat           = Int('G')
    # build list
    empty_list         = Int(']')
    append             = Int('a')
    appends            = Int('e')
    list               = Int('l')
    # build tuples
    empty_tuple        = Int(')')
    tuple              = Int('t')
    tuple1             = 0x85
    tuple2             = 0x86
    tuple3             = 0x87
    # build dicts
    empty_dict         = Int('}')
    dict               = Int('d')
    setitem            = Int('s')
    setitems           = Int('u')
    # build sets
    empty_set          = 0x8f
    additems           = 0x90
    # build frozensets
    frozenset          = 0x91
    # stack manipulation
    pop                = Int('0')
    dup                = Int('2')
    mark               = Int('(')
    pop_mark           = Int('1')
    # memo manipulation
    get                = Int('g')
    binget             = Int('h')
    long_binget        = Int('j')
    put                = Int('p')
    binput             = Int('q')
    long_binput        = Int('r')
    memoize            = 0x94
    # extension registry
    ext1               = 0x82
    ext2               = 0x83
    ext4               = 0x84
    # push class or function to stack by module and name
    Global             = Int('c')
    stack_Global       = 0x93
    # build unknown objects
    reduce             = Int('R')
    build              = Int('b')
    inst               = Int('i')
    obj                = Int('o')
    newobj             = 0x81
    newobj_ex          = 0x92
    # machine control
    proto              = 0x80
    stop               = Int('.')
    # Framing support
    frame              = 0x95
    # persistent IDs
    persid             = Int('P')
    binpersid          = Int('Q')
end

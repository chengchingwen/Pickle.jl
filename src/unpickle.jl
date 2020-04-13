mutable struct UnPickler
  memo::Dict
  stack::Vector
  metastack::Vector
  proto::Int
end

UnPickler(memo=Dict()) = UnPickler(memo, [], [], 4)

function pop_mark!(upkr::UnPickler)
  item = upkr.stack
  upkr.stack = pop!(upkr.metastack)
  return item
end


function execute!(upkr::UnPickler, op::OpCode, io::IO)
  argf = argument(op)
  arg = isnothing(argf) ? nothing : argf(io)

  execute!(upkr, Val(op), arg)
end

execute!(upkr::UnPickler, ::Val{INT}, arg) = push!(upkr.stack, arg)
execute!(upkr::UnPickler, ::Val{BININT}, arg) = push!(upkr.stack, Int(arg))
execute!(upkr::UnPickler, ::Val{BININT1}, arg) = push!(upkr.stack, Int(arg))
execute!(upkr::UnPickler, ::Val{BININT2}, arg) = push!(upkr.stack, Int(arg))
execute!(upkr::UnPickler, ::Val{LONG}, arg) = push!(upkr.stack, arg)
execute!(upkr::UnPickler, ::Val{LONG1}, arg) = push!(upkr.stack, arg)
execute!(upkr::UnPickler, ::Val{LONG4}, arg) = push!(upkr.stack, arg)
execute!(upkr::UnPickler, ::Val{STRING}, arg) = push!(upkr.stack, arg)
execute!(upkr::UnPickler, ::Val{BINSTRING}, arg) = push!(upkr.stack, arg)
execute!(upkr::UnPickler, ::Val{SHORT_BINSTRING}, arg) = push!(upkr.stack, arg)
execute!(upkr::UnPickler, ::Val{BINBYTES}, arg) = push!(upkr.stack, arg)
execute!(upkr::UnPickler, ::Val{SHORT_BINBYTES}, arg) = read_bytes1
execute!(upkr::UnPickler, ::Val{BINBYTES8}, arg) = push!(upkr.stack, arg)
execute!(upkr::UnPickler, ::Val{BYTEARRAY8}, arg) = push!(upkr.stack, arg)

# execute!(upkr::UnPickler, ::Val{NEXT_BUFFER}, arg) = nothing
# execute!(upkr::UnPickler, ::Val{READONLY_BUFFER}, arg) = nothing

execute!(upkr::UnPickler, ::Val{NONE}, arg) = push!(upkr.stack, nothing)
execute!(upkr::UnPickler, ::Val{NEWTRUE}, arg) = push!(upkr.stack, true)
execute!(upkr::UnPickler, ::Val{NEWFALSE}, arg) = push!(upkr.stack, false)
execute!(upkr::UnPickler, ::Val{UNICODE}, arg) = push!(upkr.stack, arg)
execute!(upkr::UnPickler, ::Val{SHORT_BINUNICODE}, arg) = push!(upkr.stack, arg)
execute!(upkr::UnPickler, ::Val{BINUNICODE}, arg) = push!(upkr.stack, arg)
execute!(upkr::UnPickler, ::Val{BINUNICODE8}, arg) = push!(upkr.stack, arg)
execute!(upkr::UnPickler, ::Val{FLOAT}, arg) = push!(upkr.stack, arg)
execute!(upkr::UnPickler, ::Val{BINFLOAT}, arg) = push!(upkr.stack, arg)
execute!(upkr::UnPickler, ::Val{EMPTY_LIST}, arg) = push!(upkr.stack, [])

function execute!(upkr::UnPickler, ::Val{APPEND}, arg)
  value = pop!(upkr.stack)
  push!(upkr.stack[end], value)
end

function execute!(upkr::UnPickler, ::Val{APPENDS}, arg)
  items = pop_mark!(upkr)
  append!(upkr.stack[end], items)
end

function execute!(upkr::UnPickler, ::Val{LIST}, arg)
  items = pop_mark!(upkr)
  push!(upkr.stack, items)
end

execute!(upkr::UnPickler, ::Val{EMPTY_TUPLE}, arg) = push!(upkr.stack, ())

function execute!(upkr::UnPickler, ::Val{TUPLE}, arg)
  items = Tuple(pop_mark!(upkr))
  push!(upkr.stack, items)
end

execute!(upkr::UnPickler, ::Val{TUPLE1}, arg) = upkr.stack[end] = (upkr.stack[end],)
function execute!(upkr::UnPickler, ::Val{TUPLE2}, arg)
  r = pop!(upkr.stack)
  upkr.stack[end] = (upkr.stack[end], r)
end
function execute!(upkr::UnPickler, ::Val{TUPLE3}, arg)
  r = pop!(upkr.stack)
  m = pop!(upkr.stack)
  upkr.stack[end] = (upkr.stack[end], m, r)
end
execute!(upkr::UnPickler, ::Val{EMPTY_DICT}, arg) = push!(upkr.stack, Dict())


function execute!(upkr::UnPickler, ::Val{DICT}, arg)
  items = pop_mark!(upkr)
  push!(upkr.stack, Dict(items[i]=>items[i+1] for i = 1:2:length(items)))
end

function execute!(upkr::UnPickler, ::Val{SETITEM}, arg)
  value = pop!(upkr.stack)
  key = pop!(upkr.stack)
  dict = upkr.stack[end]
  dict[key] = value
end

function execute!(upkr::UnPickler, ::Val{SETITEMS}, arg)
  items = pop_mark!(upkr)
  dict = upkr.stack[end]
  for i in 1:2:length(items)
    dict[items[i]] = items[i+1]
  end
end

execute!(upkr::UnPickler, ::Val{EMPTY_SET}, arg) = push!(upkr.stack, Set())

function execute!(upkr::UnPickler, ::Val{ADDITEMS}, arg)
  items = pop_mark!(upkr)
  obj = upkr.stack[end]
  for item in items
    push!(obj, item)
  end
end

execute!(upkr::UnPickler, ::Val{FROZENSET}, arg) = execute!(upkr, Val(EMPTY_SET), arg)
execute!(upkr::UnPickler, ::Val{POP}, arg) = isempty(upkr.stack) ? pop!(upkr.stack) : pop_mark!(upkr)
execute!(upkr::UnPickler, ::Val{DUP}, arg) = push!(upkr.stack, upkr.stack[end])
function execute!(upkr::UnPickler, ::Val{MARK}, arg)
  push!(upkr.metastack, upkr.stack)
  upkr.stack = []
end
function execute!(upkr::UnPickler, ::Val{POP_MARK}, arg)
  pop_mark!(upkr)
end

execute!(upkr::UnPickler, ::Val{GET}, arg) = push!(upkr.stack, upkr.memo[arg])
execute!(upkr::UnPickler, ::Val{BINGET}, arg) = push!(upkr.stack, upkr.memo[arg])
execute!(upkr::UnPickler, ::Val{LONG_BINGET}, arg) = push!(upkr.stack, upkr.memo[Int(arg)])

function execute!(upkr::UnPickler, ::Val{PUT}, arg)
  upkr.memo[arg] = upkr.stack[end]
end
function execute!(upkr::UnPickler, ::Val{BINPUT}, arg)
  upkr.memo[arg] = upkr.stack[end]
end
function execute!(upkr::UnPickler, ::Val{LONG_BINPUT}, arg)
  upkr.memo[arg] = upkr.stack[end]
end
function execute!(upkr::UnPickler, ::Val{MEMOIZE}, arg)
  upkr.memo[length(upkr.memo)] = upkr.stack[end]
end


# execute!(upkr::UnPickler, ::Val{EXT1}, arg) = read_uint1
# execute!(upkr::UnPickler, ::Val{EXT2}, arg) = read_uint2
# execute!(upkr::UnPickler, ::Val{EXT4}, arg) = read_int4
# execute!(upkr::UnPickler, ::Val{GLOBAL}, arg) = read_stringnl_noescape_pair
# execute!(upkr::UnPickler, ::Val{STACK_GLOBAL}, arg) = nothing
# execute!(upkr::UnPickler, ::Val{REDUCE}, arg) = nothing
# execute!(upkr::UnPickler, ::Val{BUILD}, arg) = nothing
# execute!(upkr::UnPickler, ::Val{INST}, arg) = read_stringnl_noescape_pair
# execute!(upkr::UnPickler, ::Val{OBJ}, arg) = nothing
# execute!(upkr::UnPickler, ::Val{NEWOBJ}, arg) = nothing
# execute!(upkr::UnPickler, ::Val{NEWOBJ_EX}, arg) = nothing


function execute!(upkr::UnPickler, ::Val{PROTO}, arg)
  upkr.proto = arg
end
function execute!(upkr::UnPickler, ::Val{STOP}, arg)
  pop!(upkr.stack)
end

# execute!(upkr::UnPickler, ::Val{FRAME}, arg) = read_uint8

execute!(upkr::UnPickler, ::Val{PERSID}, arg) = push!(upkr.stack, arg)
function execute!(upkr::UnPickler, ::Val{BINPERSID}, arg)
  pid = pop!(upkr.stack)
  x = persistent_load(upkr, pid)
  push!(upkr.stack, x)
end

function load(upkr::UnPickler, io::IO)
  while !eof(io)
    opcode = read(io, OpCode)

    value = execute!(upkr, opcode, io)

    isequal(STOP)(opcode) && return value
  end
end

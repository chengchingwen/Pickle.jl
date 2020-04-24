mutable struct UnPickler
  memo::Dict
  stack::Vector
  metastack::Vector
  proto::Int
  defer::Bool
end

UnPickler(memo=Dict(); defer=true) = UnPickler(memo, [], [], 4, defer)

const mt_table = Dict()

function pop_mark!(upkr::UnPickler)
  item = upkr.stack
  upkr.stack = pop!(upkr.metastack)
  return item
end

function execute!(upkr::UnPickler, op::OpCode, io::IO)
  argf = OpCodes.argument(op)
  arg = isnothing(argf) ? nothing : argf(io)

  execute!(upkr, Val(op), arg)
end

execute!(upkr::UnPickler, ::Val{OpCodes.INT}, arg) = push!(upkr.stack, arg)
execute!(upkr::UnPickler, ::Val{OpCodes.BININT}, arg) = push!(upkr.stack, Int(arg))
execute!(upkr::UnPickler, ::Val{OpCodes.BININT1}, arg) = push!(upkr.stack, Int(arg))
execute!(upkr::UnPickler, ::Val{OpCodes.BININT2}, arg) = push!(upkr.stack, Int(arg))
execute!(upkr::UnPickler, ::Val{OpCodes.LONG}, arg) = push!(upkr.stack, arg)
execute!(upkr::UnPickler, ::Val{OpCodes.LONG1}, arg) = push!(upkr.stack, arg)
execute!(upkr::UnPickler, ::Val{OpCodes.LONG4}, arg) = push!(upkr.stack, arg)
execute!(upkr::UnPickler, ::Val{OpCodes.STRING}, arg) = push!(upkr.stack, arg)
execute!(upkr::UnPickler, ::Val{OpCodes.BINSTRING}, arg) = push!(upkr.stack, arg)
execute!(upkr::UnPickler, ::Val{OpCodes.SHORT_BINSTRING}, arg) = push!(upkr.stack, arg)
execute!(upkr::UnPickler, ::Val{OpCodes.BINBYTES}, arg) = push!(upkr.stack, arg)
execute!(upkr::UnPickler, ::Val{OpCodes.SHORT_BINBYTES}, arg) = push!(upkr.stack, arg)
execute!(upkr::UnPickler, ::Val{OpCodes.BINBYTES8}, arg) = push!(upkr.stack, arg)
execute!(upkr::UnPickler, ::Val{OpCodes.BYTEARRAY8}, arg) = push!(upkr.stack, arg)

# execute!(upkr::UnPickler, ::Val{OpCodes.NEXT_BUFFER}, arg) = nothing
# execute!(upkr::UnPickler, ::Val{OpCodes.READONLY_BUFFER}, arg) = nothing

execute!(upkr::UnPickler, ::Val{OpCodes.NONE}, arg) = push!(upkr.stack, nothing)
execute!(upkr::UnPickler, ::Val{OpCodes.NEWTRUE}, arg) = push!(upkr.stack, true)
execute!(upkr::UnPickler, ::Val{OpCodes.NEWFALSE}, arg) = push!(upkr.stack, false)
execute!(upkr::UnPickler, ::Val{OpCodes.UNICODE}, arg) = push!(upkr.stack, arg)
execute!(upkr::UnPickler, ::Val{OpCodes.SHORT_BINUNICODE}, arg) = push!(upkr.stack, arg)
execute!(upkr::UnPickler, ::Val{OpCodes.BINUNICODE}, arg) = push!(upkr.stack, arg)
execute!(upkr::UnPickler, ::Val{OpCodes.BINUNICODE8}, arg) = push!(upkr.stack, arg)
execute!(upkr::UnPickler, ::Val{OpCodes.FLOAT}, arg) = push!(upkr.stack, arg)
execute!(upkr::UnPickler, ::Val{OpCodes.BINFLOAT}, arg) = push!(upkr.stack, arg)
execute!(upkr::UnPickler, ::Val{OpCodes.EMPTY_LIST}, arg) = push!(upkr.stack, [])

function execute!(upkr::UnPickler, ::Val{OpCodes.APPEND}, arg)
  value = pop!(upkr.stack)
  push!(upkr.stack[end], value)
end

function execute!(upkr::UnPickler, ::Val{OpCodes.APPENDS}, arg)
  items = pop_mark!(upkr)
  append!(upkr.stack[end], items)
end

function execute!(upkr::UnPickler, ::Val{OpCodes.LIST}, arg)
  items = pop_mark!(upkr)
  push!(upkr.stack, items)
end

execute!(upkr::UnPickler, ::Val{OpCodes.EMPTY_TUPLE}, arg) = push!(upkr.stack, ())

function execute!(upkr::UnPickler, ::Val{OpCodes.TUPLE}, arg)
  items = Tuple(pop_mark!(upkr))
  push!(upkr.stack, items)
end

execute!(upkr::UnPickler, ::Val{OpCodes.TUPLE1}, arg) = upkr.stack[end] = (upkr.stack[end],)
function execute!(upkr::UnPickler, ::Val{OpCodes.TUPLE2}, arg)
  r = pop!(upkr.stack)
  upkr.stack[end] = (upkr.stack[end], r)
end
function execute!(upkr::UnPickler, ::Val{OpCodes.TUPLE3}, arg)
  r = pop!(upkr.stack)
  m = pop!(upkr.stack)
  upkr.stack[end] = (upkr.stack[end], m, r)
end
execute!(upkr::UnPickler, ::Val{OpCodes.EMPTY_DICT}, arg) = push!(upkr.stack, Dict())


function execute!(upkr::UnPickler, ::Val{OpCodes.DICT}, arg)
  items = pop_mark!(upkr)
  push!(upkr.stack, Dict(items[i]=>items[i+1] for i = 1:2:length(items)))
end

function execute!(upkr::UnPickler, ::Val{OpCodes.SETITEM}, arg)
  value = pop!(upkr.stack)
  key = pop!(upkr.stack)
  dict = upkr.stack[end]
  dict[key] = value
end

function execute!(upkr::UnPickler, ::Val{OpCodes.SETITEMS}, arg)
  items = pop_mark!(upkr)
  dict = upkr.stack[end]
  for i in 1:2:length(items)
    dict[items[i]] = items[i+1]
  end
end

execute!(upkr::UnPickler, ::Val{OpCodes.EMPTY_SET}, arg) = push!(upkr.stack, Set())

function execute!(upkr::UnPickler, ::Val{OpCodes.ADDITEMS}, arg)
  items = pop_mark!(upkr)
  obj = upkr.stack[end]
  for item in items
    push!(obj, item)
  end
end

execute!(upkr::UnPickler, ::Val{OpCodes.FROZENSET}, arg) = execute!(upkr, Val(EMPTY_SET), arg)
execute!(upkr::UnPickler, ::Val{OpCodes.POP}, arg) = isempty(upkr.stack) ? pop!(upkr.stack) : pop_mark!(upkr)
execute!(upkr::UnPickler, ::Val{OpCodes.DUP}, arg) = push!(upkr.stack, upkr.stack[end])
function execute!(upkr::UnPickler, ::Val{OpCodes.MARK}, arg)
  push!(upkr.metastack, upkr.stack)
  upkr.stack = []
end
function execute!(upkr::UnPickler, ::Val{OpCodes.POP_MARK}, arg)
  pop_mark!(upkr)
end

execute!(upkr::UnPickler, ::Val{OpCodes.GET}, arg) = push!(upkr.stack, upkr.memo[arg])
execute!(upkr::UnPickler, ::Val{OpCodes.BINGET}, arg) = push!(upkr.stack, upkr.memo[arg])
execute!(upkr::UnPickler, ::Val{OpCodes.LONG_BINGET}, arg) = push!(upkr.stack, upkr.memo[Int(arg)])

function execute!(upkr::UnPickler, ::Val{OpCodes.PUT}, arg)
  upkr.memo[arg] = upkr.stack[end]
end
function execute!(upkr::UnPickler, ::Val{OpCodes.BINPUT}, arg)
  upkr.memo[arg] = upkr.stack[end]
end
function execute!(upkr::UnPickler, ::Val{OpCodes.LONG_BINPUT}, arg)
  upkr.memo[arg] = upkr.stack[end]
end
function execute!(upkr::UnPickler, ::Val{OpCodes.MEMOIZE}, arg)
  upkr.memo[length(upkr.memo)] = upkr.stack[end]
end


# execute!(upkr::UnPickler, ::Val{OpCodes.EXT1}, arg) = read_uint1
# execute!(upkr::UnPickler, ::Val{OpCodes.EXT2}, arg) = read_uint2
# execute!(upkr::UnPickler, ::Val{OpCodes.EXT4}, arg) = read_int4

struct Defer{F}
  name::String
  f::F
end

Defer(name::String) = f->Defer(name, f)

function Base.show(io::IO, def::Defer)
  print(io, "<Deferred $(def.name)>")
end

_get(def::Defer) = def.f()
_get(x) = x
_get(arr::Union{Array, Tuple, NTuple}) = isdefer(arr) ? map(_get, arr) : arr
_get(p::Pair) = isdefer(p) ? _get(p[0])=>_get(p[1]) : p
_get(dict::Dict) = isdefer(dict) ? Dict(_get(k)=>_get(v) for (k, v) in dict) : dict

(def::Defer)() = _get(def)

isdefer(::Defer) = true
isdefer(x) = false
isdefer(arr::Union{Array, Tuple, NTuple}) = any(isdefer, arr)
isdefer(p::Pair) = isdefer(p[1]) || isdefer(p[2])
isdefer(dict::Dict) = any(isdefer, pairs(dict))

function _defer(md, fn, defer)
  @info "loading $(md).$(fn)"
  return function (args...; kwargs...)
    global mt_table
    @info "calling $(md).$(fn)($(join(args, ", ")); $(join(kwargs, ", ")))"
    real_fn = get(mt_table, (md, fn), nothing)
    if isnothing(real_fn)
      if defer
        @info "$(md).$(fn) is not defined in `mt_table`. deferring function call."
        return (() -> mt_table[(md, fn)](args..., kwargs...)) |> Defer(join((md, fn), '.'))
      else
        error("$(md).$(fn) is not defined in `mt_table`.")
      end
    else
      return real_fn(args...; kwargs...)
    end
  end
end

execute!(upkr::UnPickler, ::Val{OpCodes.GLOBAL}, arg) = push!(upkr.stack, _defer(arg..., upkr.defer))

function execute!(upkr::UnPickler, ::Val{OpCodes.STACK_GLOBAL}, arg)
  fn = pop!(upkr.stack)
  md = pop!(upkr.stack)
  push!(upkr.stack, _defer(md, fn, upkr.defer))
end

function execute!(upkr::UnPickler, ::Val{OpCodes.REDUCE}, arg)
  args = pop!(upkr.stack)
  fn = upkr.stack[end]
  @info "reducing $fn with $args"
  if isdefer(fn) || isdefer(args)
    @info "deferring reduce"
    upkr.stack[end] = (() -> _get(fn)(_get(args)...)) |> Defer(string(fn))
  else
    upkr.stack[end] = fn(args...)
  end
end

function setstate! end

# this is very likely to break
function _build!(inst, state)
  @info "building"
  if applicable(setstate!, inst)
    return setstate!(inst, state)
  else
    if state isa Tuple && length(state) == 2
      state, slotstate = state
    else
      slotstate = nothing
    end

    if !isnothing(state)
      for (k, v) in pairs(state)
        setfield!(inst, Symbol(k), v)
      end
    end

    if !isnothing(slotstate)
      for (k, v) in pairs(slotstate)
        setfield!(inst, Symbol(k), v)
      end
    end
    return inst
  end
end

function execute!(upkr::UnPickler, ::Val{OpCodes.BUILD}, arg)
  state = pop!(upkr.stack)
  inst = upkr.stack[end]
  @info "building $inst with $state"
  if isdefer(inst) || isdefer(state)
    @info "deferring build"
    upkr.stack[end] = (()-> _build!(_get(inst), _get(state))) |> Defer(string("_build ", inst))
  else
    return _build!(inst, state)
  end
end

function execute!(upkr::UnPickler, ::Val{OpCodes.INST}, arg)
  init = _defer(arg..., upkr.defer)
  args = pop_mark!(upkr)
  @info "instantiatiating $init with $args"
  push!(upkr.stack, init(args...))
end

function execute!(upkr::UnPickler, ::Val{OpCodes.OBJ}, arg)
  args = pop_mark!(upkr)
  init = pop!(upkr.stack)
  @info "instantiatiating $init with $args"
  if isdefer(init) || isdefer(args)
    @info "deferring instantiatiate"
    push!(upkr.stack,
          (()->_get(init)(_get(args)...)) |> Defer(string(inst)))
  else
    push!(upkr.stack, init(args...))
  end
end

function execute!(upkr::UnPickler, ::Val{OpCodes.NEWOBJ}, arg)
  args = pop!(upkr.stack)
  init = pop!(upkr.stack)
  @info "new object $init with $args"
  if isdefer(init) || isdefer(args)
    @info "deferring new"
    push!(upkr.stack,
          (()->_get(init)(_get(args)...)) |> Defer(string(init)))
  else
    push!(upkr.stack, init(args...))
  end
end

function execute!(upkr::UnPickler, ::Val{OpCodes.NEWOBJ_EX}, arg)
  kwargs = pop!(upkr.stack)
  args = pop!(upkr.stack)
  init = pop!(upkr.stack)
  @info "new object $init with $args and $kwargs"
  if isdefer(init) || isdefer(args)
    @info "deferring new"
    push!(upkr.stack,
          (()->_get(init)(_get(args)...; _get(kwargs)...)) |> Defer(string(init)))
  else
    push!(upkr.stack, init(args...; kwargs...))
  end
end

function execute!(upkr::UnPickler, ::Val{OpCodes.PROTO}, arg)
  upkr.proto = arg
end
function execute!(upkr::UnPickler, ::Val{OpCodes.STOP}, arg)
  pop!(upkr.stack)
end

# execute!(upkr::UnPickler, ::Val{OpCodes.FRAME}, arg) = read_uint8

execute!(upkr::UnPickler, ::Val{OpCodes.PERSID}, arg) = push!(upkr.stack, arg)
function execute!(upkr::UnPickler, ::Val{OpCodes.BINPERSID}, arg)
  pid = pop!(upkr.stack)
  x = persistent_load(upkr, pid)
  push!(upkr.stack, x)
end

persistent_load(::UnPickler, pid) = error("unsupported persistent id encountered")

load(io::IO) = load(UnPickler(), io)
function load(upkr::UnPickler, io::IO)
  while !eof(io)
    opcode = read(io, OpCode)

    value = execute!(upkr, opcode, io)

    isequal(OpCodes.STOP)(opcode) && return value
  end
end

loads(s) = loads(UnPickler(), s)
loads(upkr::UnPickler, s) = load(upkr, IOBuffer(s))

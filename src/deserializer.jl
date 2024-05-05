Serialization.deserialize(p::AbstractPickle, file::AbstractString) = open(file, "r") do io
  Serialization.deserialize(p,  io)
end
Serialization.deserialize(p::AbstractPickle, io::IO) = load(p, io)

loads(s; proto=DEFAULT_PROTO) = loads(Pickler(proto), s)
loads(p::AbstractPickle, s) = load(p, IOBuffer(s))

load(file::AbstractString; proto=DEFAULT_PROTO) = open(f->load(f; proto=proto), file)
load(io::IO; proto=DEFAULT_PROTO) = load(Pickler(proto), io)
load(p::AbstractPickle, file::AbstractString) = open(f->load(p, f), file)
function load(p::AbstractPickle, io::IO)
  while !eof(io)
    opcode = read(io, OpCode)
    run!(p, opcode, io)

    isequal(OpCodes.STOP)(opcode) && return pop!(p.stack)
  end
end

function run!(p::AbstractPickle, op::OpCode, io::IO)
  argf = OpCodes.argument(op)
  arg = isnothing(argf) ? nothing : argf(io)

  execute!(p, Val(op), arg)
end

for op in :(INT, LONG, LONG1, LONG4,
            STRING, BINSTRING, SHORT_BINSTRING,
            BYTEARRAY8,
            UNICODE, SHORT_BINUNICODE, BINUNICODE, BINUNICODE8,
            FLOAT, BINFLOAT).args
  @eval execute!(p::AbstractPickle, ::Val{OpCodes.$op}, arg) = push!(p.stack, arg)
end

for op in :(BINBYTES, SHORT_BINBYTES, BINBYTES8).args
  @eval execute!(p::AbstractPickle, ::Val{OpCodes.$op}, arg) = push!(p.stack, codeunits(String(arg)))
end

for op in :(BININT, BININT1, BININT2).args
  @eval execute!(p::AbstractPickle, ::Val{OpCodes.$op}, arg) = push!(p.stack, Int(arg))
end

for (op, arg) in zip(
  :(NONE, NEWTRUE, NEWFALSE, EMPTY_LIST, EMPTY_TUPLE, EMPTY_DICT, EMPTY_SET).args,
  :(nothing, true, false, [], (), Dict(), Set()).args
)
  @eval execute!(p::AbstractPickle, ::Val{OpCodes.$op}, arg) = push!(p.stack, $arg)
end


"""
  similar to `Expr` but mutable

Used to hold an unconstructable object. Requires mutable for pickle memo work.
"""
mutable struct Defer
  head::Symbol
  args::Vector{Any}

  Defer(t::Tuple) = new(t...)
  Defer(head, @nospecialize(args...)) = new(head, collect(Any, args))
end

function show(io::IO, def::Defer)
  if isempty(def.args)
    print(io, "Defer(:$(def.head))")
  else
    print(io, "Defer(:$(def.head), ")
    join(io, def.args, ", ")
    print(io, ')')
  end
end

function wrap!(def::Defer, tag, @nospecialize(args...))
  old_def = Defer((def.head, def.args))
  def.head = tag
  def.args = [old_def, args...]
  def
end

isdefer(::Defer) = true
isdefer(c::Union{Array, Tuple, Set}) = any(isdefer, c)
isdefer(d::Dict) = any(isdefer, values(d)) || any(isdefer, keys(d))
isdefer(x) = false


macro deferexecutef(op, tag, popf, pushf)
  return quote
  end
end

_setkey!(obj, rpair) = setindex!(obj, rpair...)
_setkeys!(obj, pairs) = foreach(i->setindex!(obj, pairs[i+1], pairs[i]), 1:2:length(pairs))
_addvalue(obj, values) = foreach(x->push!(obj, x), values)

for (op, tag, popf, pushf) in (
  (:APPEND,   :(:append),   pop!,    push!),
  (:APPENDS,  :(:appends),  unmark!, append!),
  (:SETITEM,  :(:setitem),  pop2!,   _setkey!),
  (:SETITEMS, :(:setitems), unmark!, _setkeys!),
  (:ADDITEMS, :(:additems), unmark!, _addvalue))
  @eval function execute!(p::AbstractPickle, ::Val{OpCodes.$op}, @nospecialize(arg))
    value = $popf(p.stack)
    obj = first(p.stack)
    if obj isa Defer
      if obj.head == $tag
        push!(obj.args, value)
      else
        wrap!(obj, $tag, value)
      end
    else
      $pushf(obj, value)
    end
  end
end

execute!(p::AbstractPickle, ::Val{OpCodes.LIST}, arg) = push!(p.stack, unmark!(p.stack))
execute!(p::AbstractPickle, ::Val{OpCodes.TUPLE}, arg) = push!(p.stack, Tuple(unmark!(p.stack)))

execute!(p::AbstractPickle, ::Val{OpCodes.TUPLE1}, arg) = push!(p.stack, tuple(pop!(p.stack)))
execute!(p::AbstractPickle, ::Val{OpCodes.TUPLE2}, arg) = push!(p.stack, reverse(pop2!(p.stack)))

execute!(p::AbstractPickle, ::Val{OpCodes.TUPLE3}, arg) = push!(p.stack, reverse(pop3!(p.stack)))

function execute!(p::AbstractPickle, ::Val{OpCodes.DICT}, arg)
  pairs = unmark!(p.stack)
  push!(p.stack, Dict(pairs[i]=>pairs[i+1] for i = 1:2:length(pairs)))
end

execute!(p::AbstractPickle, ::Val{OpCodes.POP}, arg) =
  isempty(p.stack) ? unmark!(p.stack) : pop!(p.stack)
execute!(p::AbstractPickle, ::Val{OpCodes.DUP}, arg) = push!(p.stack, first(p.stack))
execute!(p::AbstractPickle, ::Val{OpCodes.MARK}, arg) = mark!(p.stack)
execute!(p::AbstractPickle, ::Val{OpCodes.POP_MARK}, arg) = unmark!(p.stack)

for op in :(GET, BINGET, LONG_BINGET).args
  @eval execute!(p::AbstractPickle, ::Val{OpCodes.$op}, arg) =
    push!(p.stack, p.memo[Int(arg)])
end

for op in :(PUT, BINPUT, LONG_BINPUT).args
  @eval execute!(p::AbstractPickle, ::Val{OpCodes.$op}, arg) =
    setindex!(p.memo, first(p.stack), Int(arg))
end

execute!(p::AbstractPickle, ::Val{OpCodes.MEMOIZE}, arg) =
  setindex!(p.memo, first(p.stack), length(p.memo))

function execute!(p::AbstractPickle, ::Val{OpCodes.FROZENSET}, arg)
  fz = lookup(p.mt, "__main__", "frozenset")
  obj = isnothing(fz) ? Defer(gensym(:frozenset)) : fz()
  push!(p.stack, obj)
end

function execute!(p::AbstractPickle, ::Val{OpCodes.GLOBAL}, arg)
  func = lookup(p.mt, arg...)
  obj = isnothing(func) ? Defer(Symbol(join(arg, '.'))) : func
  push!(p.stack, obj)
end

function execute!(p::AbstractPickle, ::Val{OpCodes.STACK_GLOBAL}, arg)
  name = pop!(p.stack)
  scope = pop!(p.stack)
  func = lookup(p.mt, scope, name)
  obj = isnothing(func) ? Defer(Symbol(join((scope, name), '.'))) : func
  push!(p.stack, obj)
end

function execute!(p::AbstractPickle, ::Val{OpCodes.REDUCE}, arg)
  args = pop!(p.stack)
  f = first(p.stack)
  res = f isa Defer ? Defer(:reduce, f, args...) : f(args...)

  updatefirst!(p.stack, res)
end

execute!(p::AbstractPickle, ::Val{OpCodes.PROTO}, arg) = @assert protocol(p) >= arg """Incompatible protocol version:
    Trying to load version $arg pickle file with version $(protocol(p)) pickler.
    Try setting the `proto` keyword argument when loading, e.g. `load(file; proto = $arg)`.
    If that still fails, please open an issue.
"""

# FRAMEING is ignored, but can be added if we find that performance is bounded by I/O
for op in :(STOP, FRAME).args
  @eval execute!(p::AbstractPickle, ::Val{OpCodes.$op}, arg) = nothing
end

function execute!(p::AbstractPickle, ::Val{OpCodes.PERSID}, arg)
  f = lookup(p.mt, "persistent_load")
  obj = isnothing(f) ? Defer(:persistent_load, arg) : f(arg)
  push!(p.stack, obj)
end

function execute!(p::AbstractPickle, ::Val{OpCodes.BINPERSID}, arg)
  f = lookup(p.mt, "persistent_load")
  pid = pop!(p.stack)
  obj = isnothing(f) ? Defer(:persistent_load, pid) : f(pid)
  push!(p.stack, obj)
end

function execute!(p::AbstractPickle, ::Val{OpCodes.INST}, arg)
  f = lookup(p.mt, arg...)
  args = unmark!(p.stack)
  res = isnothing(f) ? Defer(:inst, f, args...) : f(args...)
  push!(p.stack, res)
end

function execute!(p::AbstractPickle, ::Val{OpCodes.OBJ}, arg)
  args = unmark!(p.stack)
  cls = popfirst!(args)
  res = cls isa Defer ? Defer(:obj, cls, args...) : cls(args...)
  push!(p.stack, res)
end

function execute!(p::AbstractPickle, ::Val{OpCodes.NEWOBJ}, arg)
  args, cls = pop2!(p.stack)
  res = cls isa Defer ? Defer(:newobj, cls, args...) : cls(args...)
  push!(p.stack, res)
end

function execute!(p::AbstractPickle, ::Val{OpCodes.NEWOBJ_EX}, arg)
  kwargs, args, cls = pop3!(p.stack)
  if cls isa Defer
    res = Defer(:newobj_ex, cls, kwargs, args...)
  else
    res = cls(args...; kwargs...)
  end
  push!(p.stack, res)
end

function objtypename(t)
  T = typeof(t)
  join((fullname(parentmodule(T))..., Base.typename(T).name), '.')
end

function execute!(p::AbstractPickle, ::Val{OpCodes.BUILD}, arg)
  args = pop!(p.stack)
  obj = first(p.stack)
  if obj isa Defer
    wrap!(obj, :build, args)
  else
    build = lookup(p.mt, "__build__", objtypename(obj)) # hack for dispatch
    if isnothing(build)
      newobj = Defer(:build, obj, args)
    else
      newobj = build(obj, args)
    end
    hasref(p.memo, obj) &&
      maybeupdate!(p.memo, obj, newobj)
    maybeupdatefirst!(p.stack, newobj)
  end
end

# PROTOCOL 5 is not supported.
# execute!(p::AbstractPickle, ::Val{OpCodes.NEXT_BUFFER}, arg) = nothing
# execute!(p::AbstractPickle, ::Val{OpCodes.READONLY_BUFFER}, arg) = nothing

# Extension is not supported, file an issue if you need it.
# execute!(p::AbstractPickle, ::Val{OpCodes.EXT1}, arg) = read_uint1
# execute!(p::AbstractPickle, ::Val{OpCodes.EXT2}, arg) = read_uint2
# execute!(p::AbstractPickle, ::Val{OpCodes.EXT4}, arg) = read_int4

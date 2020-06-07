using InternedStrings

# batch size for batch appends/setitems
const BATCHSIZE = Ref(1000)

serialize(file::AbstractString, x) = Serialization.serialize(Pickler(), file, x)
Serialization.serialize(p::AbstractPickle, file::AbstractString, x) = open(file, "w+") do io
  Serialization.serialize(p, io, x)
end
Serialization.serialize(p::AbstractPickle, io::IO, x) = store(p, io, x)

stores(x; proto=DEFAULT_PROTO) = stores(Pickler(proto), x)
stores(p, x) = sprint((io, x)->store(p, io, x), x)

store(io::IO, x; proto=DEFAULT_PROTO) = store(Pickler(proto), io, x)
function store(p::AbstractPickle, io::IO, @nospecialize(x))
  protocol(p) >= 2 && write_porotcol(p, io)
  save_object(p, io, x)
  write(io, OpCodes.STOP)
  return
end

write_porotcol(p::AbstractPickle, io::IO) = write(io, OpCodes.PROTO) + write_uint1(io, protocol(p))

save_object(p::AbstractPickle, io::IO, x) = hasref(p.memo, x) ? save_get(p, io, x) : save(p, io, x)

function memoize(p::AbstractPickle, io::IO, @nospecialize(x))
  @assert !hasref(p.memo, x)
  idx = length(p.memo)
  save_put(p, io, idx)
  p.memo[idx] = x
end

function save_put(p::AbstractPickle, io::IO, idx::Int)
  if protocol(p) >= 4
    write(io, OpCodes.MEMOIZE)
  elseif isbinary(p)
    if idx < 256
      write(io, OpCodes.BINPUT)
      write_uint1(io, idx)
    else
      write(io, OpCodes.LONG_BINPUT)
      write_uint4(io, idx)
    end
  else
    write(io, OpCodes.PUT)
    println(io, idx)
  end
end

function save_get(p::AbstractPickle, io::IO, @nospecialize(x))
  i = getref(p.memo, x)
  if isbinary(p)
    if i < 256
      write(io, OpCodes.BINGET)
      write_uint1(io, i)
    else
      write(io, OpCodes.LONG_BINGET)
      write_uint4(io, i)
    end
  else
    write(io, OpCodes.GET)
    println(io, i)
  end
end

save(p::AbstractPickle, io::IO, ::Nothing) = write(io, OpCodes.NONE)

function save(p::AbstractPickle, io::IO, x::Bool)
  if protocol(p) >= 2
    write(io, x ? OpCodes.NEWTRUE : OpCodes.NEWFALSE)
  else
    write(io, x ? b"I01\n" : b"I00\n")
  end
end

@inline function save_small_pos_bin_int(p::AbstractPickle, io::IO, x::Integer)
  if x <= 0xff
    write(io, OpCodes.BININT1)
    write_uint1(io, x)
  else
    write(io, OpCodes.BININT2)
    write_uint2(io, x)
  end
end

@inline function save_32bit_bin_int(p::AbstractPickle, io::IO, x::Integer)
  write(io, OpCodes.BININT)
  write_int4(io, x)
end

@inline function save_2s_compl_int(p::AbstractPickle, io::IO, x::Integer)
  bytes = int_to_bytes(x)
  n = length(bytes)
  if n < 256
    write(io, OpCodes.LONG1)
    write_uint1(io, n)
  else
    write(io, OpCodes.LONG4)
    write_int4(io, n)
  end
  write(io, bytes)
end

function save(p::AbstractPickle, io::IO, x::Integer)
  if isbinary(p)
    if 0 <= x <= 0xffff
      return save_small_pos_bin_int(p, io, x)
    end

    if typemin(Int32) <= x <= typemax(Int32)
      return save_32bit_bin_int(p, io, x)
    end
  end

  if protocol(p) >= 2
    return save_2s_compl_int(p, io, x)
  end

  # fallback plain text
  if typemin(Int32) <= x <= typemax(Int32)
    write(io, OpCodes.INT)
    println(io, x)
  else
    write(io, OpCodes.LONG)
    write(io, "$(x)L\n")
  end
end

save(p::AbstractPickle, io::IO, x::AbstractFloat) = save(p, io, Float64(x))
function save(p::AbstractPickle, io::IO, x::Float64)
  if isbinary(p)
    write(io, OpCodes.BINFLOAT)
    write(io, bswap(x))
  else
    write(io, OpCodes.FLOAT)
    println(io, x)
  end
end

@inline write_short_str(io, n, x) = write(io, OpCodes.SHORT_BINUNICODE) +
  write_uint1(io, n) + write(io, x)

@inline write_long_str(io, n, x) = write(io, OpCodes.BINUNICODE8) +
  write_uint8(io, n) + write(io, x)

@inline write_str(io, n, x) = write(io, OpCodes.BINUNICODE) +
  write_uint4(io, n) + write(io, x)

save(p::AbstractPickle, io::IO, x::Char) = save(p, io, string(x))
function save(p::AbstractPickle, io::IO, x::String)
  if isbinary(p)
    n = ncodeunits(x)
    if protocol(p) < 4 || 0xff < n <= 0xffffffff
      write_str(io, n, x)
    else
      if n <= 0xff
        write_short_str(io, n, x)
      else
        write_long_str(io, n, x)
      end
    end
  else
    write(io, OpCodes.UNICODE)
    write_plain_str(io, x)
    write(io, '\n')
  end
  memoize(p, io, x)
end

save(p::AbstractPickle, io::IO, x::Tuple{}) = isbinary(p) ?
  write(io, OpCodes.EMPTY_TUPLE) :
  write(io, OpCodes.MARK) + write(io, OpCodes.TUPLE)

function save(p::AbstractPickle, io::IO, x::T) where {N, T <: NTuple{N, Any}}
  if N <= 3 && protocol(p) >= 2
    foreach(i->save_object(p, io, i), x)
    if hasref(p.memo, x)
      foreach(()->write(io, OpCodes.POP), 1:N)
      save_get(p, io, x)
    else
      if N == 1
        tcode = OpCodes.TUPLE1
      elseif N == 2
        tcode = OpCodes.TUPLE2
      else
        tcode = OpCodes.TUPLE3
      end
      write(io, tcode)
      memoize(p, io, x)
    end
  else
    write(io, OpCodes.MARK)
    foreach(i->save_object(p, io, i), x)
    if hasref(p.memo, x)
      isbinary(p) ?
        write(io, OpCodes.POP_MARK) :
        foreach(()->write(io, OpCodes.POP), 0:N)
      save_get(p, io, x)
    else
      write(io, OpCodes.TUPLE)
      memoize(p, io, x)
    end
  end
end

function batch_appends(p::AbstractPickle, io::IO, x::Vector)
  if !isbinary(p)
    for i in x
      save_object(p, io, i)
      write(io, OpCodes.APPEND)
    end
  else
    global BATCHSIZE
    len = length(x)
    batch = BATCHSIZE[]
    foreach(1:batch:len) do bidx
      last = min(bidx+batch-1, len)
      if isequal(bidx, last)
        save_object(p, io, x[last])
        write(io, OpCodes.APPEND)
      else
        write(io, OpCodes.MARK)
        foreach(idx->save_object(p, io, x[idx]), bidx:last)
        write(io, OpCodes.APPENDS)
      end
    end
  end
end

function save(p::AbstractPickle, io::IO, x::Vector)
  if isbinary(p)
    write(io, OpCodes.EMPTY_LIST)
  else
    write(io, OpCodes.MARK)
    write(io, OpCodes.LIST)
  end
  memoize(p, io, x)
  batch_appends(p, io, x)
end

function batch_setitems(p::AbstractPickle, io::IO, x::Dict)
  if !isbinary(p)
    for (k, v) in x
      save_object(p, io, k)
      save_object(p, io, v)
      write(io, OpCodes.SETITEM)
    end
  else
    global BATCHSIZE
    batch = BATCHSIZE[]
    len = length(x)

    foldl(1:batch:len; init=0) do state, bidx
      last = min(bidx+batch-1, len)
      if isequal(bidx, last)
        (k, v), state = iszero(state) ?
          iterate(x) :
          iterate(x, state)

        save_object(p, io, k)
        save_object(p, io, v)
        write(io, OpCodes.SETITEM)
      else
        write(io, OpCodes.MARK)
        state = foldl(bidx:last; init=state) do state, idx
          (k, v), state = iszero(state) ?
            iterate(x) :
            iterate(x, state)

          save_object(p, io, k)
          save_object(p, io, v)
          state
        end
        write(io, OpCodes.SETITEMS)
      end
      state
    end
  end
end

function save(p::AbstractPickle, io::IO, x::Dict)
  if isbinary(p)
    write(io, OpCodes.EMPTY_DICT)
  else
    write(io, OpCodes.MARK)
    write(io, OpCodes.DICT)
  end

  memoize(p, io, x)
  batch_setitems(p, io, x)
end

function save_global(p::AbstractPickle, io::IO, Tname)
  Tname = intern(Tname)
  if hasref(p.memo, Tname)
    save_get(p, io, Tname)
  else
    pname = lookup(p.mt, "__julia__", Tname)
    @assert !isnothing(pname) "python name for `$Tname` is not registered."
    module_name, name = split(pname, '.'; limit=2)
    if protocol(p) >= 4
      save_object(p, io, module_name)
      save_object(p, io, name)
      write(io, OpCodes.STACK_GLOBAL)
    else
      write(io, OpCodes.GLOBAL)
      println(io, module_name)
      println(io, name)
    end
    memoize(p, io, Tname)
  end
end

function save(p::AbstractPickle, io::IO, x::Set)
  if protocol(p) < 4
    save_global(p, io, objtypename(x))
    save_object(p, io, (collect(x),))
    write(io, OpCodes.REDUCE)

    if hasref(p.memo, x)
      write(io, OpCodes.POP)
      save_get(p, io, x)
    else
      memoize(p, io, x)
    end
  else
    write(io, OpCodes.EMPTY_SET)
    memoize(p, io, x)

    global BATCHSIZE
    batch = BATCHSIZE[]
    len = length(x)

    foldl(1:batch:len; init=1) do state, bidx
      last = min(bidx+batch-1, len)
      write(io, OpCodes.MARK)
      state = foldl(bidx:last; init=state) do state, idx
        v, state = iterate(x, state)
        save_object(p, io, v)
        state
      end
      write(io, OpCodes.ADDITEMS)
      state
    end
  end
end

function save(p::AbstractPickle, io::IO, x::Base.CodeUnits)
  n = length(x)
  if protocol(p) < 3
    if iszero(n)
      save_global(p, io, i"__py__.bytes")
      save_object(p, io, ())
      write(io, OpCodes.REDUCE)
    else
      save_global(p, io, objtypename(x))
      save_object(p, io, (x.s, i"latin1"))
      write(io, OpCodes.REDUCE)
    end
  else
    if n < 0xff
      write(io, OpCodes.SHORT_BINBYTES)
      write_uint1(io, n)
    else
      if protocol(p) < 4 || n <= 0xffffffff
        write(io, OpCodes.BINBYTES)
        write_uint4(io, n)
      else
        write(io, OpCodes.BINBYTES8)
        write_uint8(io, n)
      end
    end
    write(io, x)
  end
end


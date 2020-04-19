using ..Pickle

const DEFAULT_PROTO = 4
const BATCHSIZE = Ref(1000)

mutable struct Pickler{PROTO}
  memo::Dict
end

Pickler(proto=DEFAULT_PROTO, memo=Dict()) = Pickler{proto}(memo)

protocal(::Pickler{P}) where {P} = P
isbinary(pklr::Pickler) = protocal(pklr) >= 1


persistent_id(x) = nothing

function memoize(pklr::Pickler, io::IO, data)
  @assert objectid(data) ∉ keys(pklr.memo) pklr.memo
  idx = length(pklr.memo)
  save_put(pklr, io, idx)
  pklr.memo[objectid(data)] = (idx, data)
end

function save(pklr::Pickler, io::IO, data; save_persistent=true)
  pid = persistent_id(data)
  !isnothing(pid) && return save_per(pklr, io, pid)
  x = get(pklr.memo, objectid(data), nothing)
  !isnothing(x) && return save_get(pklr, io, first(x))

  _save(pklr, io, data)

end

function save_put(pklr::Pickler, io::IO, idx)
  if protocal(pklr) >= 4
    write(io, OpCodes.MEMOIZE)
  elseif isbinary(pklr)
    if idx < 256
      write(io, OpCodes.BINPUT)
      Pickle.write_uint1(io, idx)
    else
      write(io, OpCodes.LONG_BINPUT)
      Pickle.write_uint4(io, idx)
    end
  else
    write(io, OpCodes.PUT)
    println(io, idx)
  end
end


function save_get(pklr::Pickler, io::IO, i)
  if isbinary(pklr)
    if i < 256
      write(io, OpCodes.BINGET)
      Pickle.write_uint1(io, i)
    else
      write(io, OpCodes.LONG_BINGET)
      Pickle.write_uint4(io, i)
    end
  else
    write(io, OpCodes.GET)
    println(io, i)
  end
end

function save_per(pklr::Pickler, io::IO, pid)
  if isbinary(pklr)
    save(pklr, io, pid; save_persistent=false)
    write(io, OpCodes.BINPERSID)
  else
    write(io, OpCodes.PERSID)
    Pickle.write_plain_str(io, string(pid))
    write(io, "\n")
  end
end

function save_reduce(pklr::Pickler, io::IO, f, data) end


_save(pklr::Pickler, io::IO, ::Nothing) = write(io, OpCodes.NONE)

function _save(pklr::Pickler, io::IO, data::Bool)
  if protocal(pklr) >= 2
    write(io, data ? OpCodes.NEWTRUE : OpCodes.NEWFALSE)
  else
    write(io, data ? OpCodes.TRUE : OpCodes.FALSE)
  end
end

function _save(pklr::Pickler, io::IO, data::Integer)
  if isbinary(pklr)
    if data >= 0
      if data <= 0xff
        write(io, OpCodes.BININT1)
        Pickle.write_uint1(io, data)
        return
      elseif data <= 0xffff
        write(io, OpCodes.BININT2)
        Pickle.write_uint2(io, data)
        return
      end
    end

    if typemin(Int32) <= data <= typemax(Int32)
      write(io, OpCodes.BININT)
      Pickle.write_int4(io, data)
      return
    end
  end

  if protocal(pklr) >= 2
    bytes = Pickle.int_to_bytes(data)
    n = length(bytes)
    if m < 256
      write(io, OpCodes.LONG1)
      Pickle.write_uint1(io, n)
    else
      write(io, OpCodes.LONG4)
      Pickle.write_int4(io, n)
    end
    write(io, bytes)
    return
  end

  if typemin(Int32) <= data <= typemax(Int32)
    write(io, OpCodes.INT)
    println(io, data)
  else
    write(io, OpCodes.LONG)
    write(io, "$(data)L\n")
  end
  return
end


function _save(pklr::Pickler, io::IO, data::Float64)
  if isbinary(pklr)
    write(io, OpCodes.BINFLOAT)
    write(io, bswap(data))
  else
    write(io, OpCodes.FLOAT)
    println(io, data)
  end
end


_save(pklr::Pickler, io::IO, data::Char) = _save(pklr, io, string(data))
function _save(pklr::Pickler, io::IO, data::String)
  if isbinary(pklr)
    n = ncodeunits(data)
    if n <= 0xff && protocal(pklr) >= 4
      write(io, OpCodes.SHORT_BINUNICODE)
      Pickle.write_uint1(io, n)
      write(io, data)
    elseif n > 0xffffffff && protocal(pklr) >= 4
      write(io, OpCodes.BINUNICODE8)
      Pickle.write_uint8(io, n)
      write(io, data)
    else
      write(io, OpCodes.BINUNICODE)
      Pickle.write_uint4(io, n)
      write(io, data)
    end
  else
    write(io, OpCodes.UNICODE)
    Pickle.write_plain_str(io, data)
    write(io, '\n')
  end
  memoize(pklr, io, data)
end

_tuplesize2code(n) = (OpCodes.EMPTY_TUPLE, OpCodes.TUPLE1, OpCodes.TUPLE2, OpCodes.TUPLE3)[n+1]

function _save(pklr::Pickler, io::IO, data::Tuple)
  if isempty(data)
    if isbinary(pklr)
      write(io, OpCodes.EMPTY_TUPLE)
    else
      write(io, OpCodes.MARK)
      write(io, OpCodes.TUPLE)
    end
    return
  end

  n = length(data)
  if n <= 3 && protocal(pklr) >= 2
    for elm ∈ data
      save(pklr, io, elm)
    end

    if objectid(data) ∈ keys(pklr.memo)
      for i in 1:n
        write(io, OpCodes.POP)
      end
      save_get(pklr, io, first(pklr.memo[objectid(data)]))
    else
      write(io, _tuplesize2code(n))
      memoize(pklr, io, data)
    end
    return
  end

  write(io, OpCodes.MARK)
  for elm ∈ data
    save(pklr, io, elm)
  end

  if objectid(data) ∈ keys(pklr.memo)
    if isbinary(pklr)
      write(io, OpCodes.POP_MARK)
    else
      for i in 0:n
        write(io, OpCodes.POP)
      end
    end
    save_get(pklr, io, first(pklr.memo[objectid(data)]))
  end

  write(io, OpCodes.TUPLE)
  memoize(pklr. io, data)
end

function batch_appends(pklr::Pickler, io::IO, data)
  if !isbinary(pklr)
    for x in data
      save(pklr, io, x)
      write(io, OpCodes.APPEND)
    end
    return
  end

  len = length(data)
  for (i, elm) ∈ enumerate(data)
    if i != len && mod1(i, BATCHSIZE[]) == 1
        write(io, OpCodes.MARK)
    end

    save(pklr, io, elm)

    if mod1(i, BATCHSIZE[]) == BATCHSIZE[]
      write(io, OpCodes.APPENDS)
    elseif i == len
      if mod1(i, BATCHSIZE[]) == 1
        write(io, OpCodes.APPEND)
      else
        write(io, OpCodes.APPENDS)
      end
    end
  end
end

function _save(pklr::Pickler, io::IO, data::Vector)
  if isbinary(pklr)
    write(io, OpCodes.EMPTY_LIST)
  else
    write(io, OpCodes.MARK)
    write(io, OpCodes.LIST)
  end
  memoize(pklr, io, data)
  batch_appends(pklr, io, data)
end

function batch_setitems(pklr::Pickler, io::IO, data::Dict)
  if !isbinary(pklr)
    for (k, v) in data
      save(pklr, io, k)
      save(pklr, io, v)
      write(io, OpCodes.SETITEM)
    end
    return
  end

  len = length(data)
  for (i, (k, v)) ∈ enumerate(data)
    if i != len && mod1(i, BATCHSIZE[]) == 1
        write(io, OpCodes.MARK)
    end

    save(pklr, io, k)
    save(pklr, io, v)

    if mod1(i, BATCHSIZE[]) == BATCHSIZE[]
      write(io, OpCodes.SETITEMS)
    elseif i == len
      if mod1(i, BATCHSIZE[]) == 1
        write(io, OpCodes.SETITEM)
      else
        write(io, OpCodes.SETITEMS)
      end
    end
  end
end

function _save(pklr::Pickler, io::IO, data::Dict)
  if isbinary(pklr)
    write(io, OpCodes.EMPTY_DICT)
  else
    write(io, OpCodes.MARK)
    write(io, OpCodes.DICT)
  end

  memoize(pklr, io, data)
  batch_setitems(pklr, io, data)
end

function _save(pklr::Pickler, io::IO, data::Set)
  if protocal(pklr) < 4
    save_reduce(pklr, io, Set, data)
    return
  end

  write(io, OpCodes.EMPTY_SET)
  memoize(pklr, io, data)

  len = length(data)
  for (i, elm) ∈ enumerate(data)
    if mod1(i, BATCHSIZE[]) == 1
        write(io, OpCodes.MARK)
    end

    save(pklr, io, elm)

    if mod1(i, BATCHSIZE[]) == BATCHSIZE[] || i == len
      write(io, OpCodes.ADDITEMS)
    end
  end
end

dump(io::IO, data) = dump(Pickler(), io, data)
function dump(pklr::Pickler, io::IO, data)
  if protocal(pklr) >= 2
    write(io, OpCodes.PROTO)
    Pickle.write_uint1(io, protocal(pklr))
  end
  save(pklr, io, data)
  write(io, OpCodes.STOP)
  io
end

dumps(data) = dumps(Pickler(), data)
dumps(pklr::Pickler, data) = sprint((io, data)->dump(pklr, io, data), data)

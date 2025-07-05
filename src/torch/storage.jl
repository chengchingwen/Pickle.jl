using BFloat16s
import Base: setindex!, getindex, haskey, pairs, keys, values

@enum DType begin
  FLOAT
  DOUBLE
  HALF
  UINT8
  INT8
  SHORT
  INT
  LONG
  BOOL
  BFLOAT16
end

jltype2dtype(::Type{Float32}) = FLOAT
jltype2dtype(::Type{Float64}) = DOUBLE
jltype2dtype(::Type{Float16}) = HALF
jltype2dtype(::Type{UInt8}) = UINT8
jltype2dtype(::Type{Int8}) = INT8
jltype2dtype(::Type{Int16}) = SHORT
jltype2dtype(::Type{Int32}) = INT
jltype2dtype(::Type{Int64}) = LONG
jltype2dtype(::Type{Bool}) = BOOL
jltype2dtype(::Type{BFloat16}) = BFLOAT16

function dtype2jltype(t::DType)
  if t == FLOAT
    return Float32
  elseif t == DOUBLE
    return Float64
  elseif t == HALF
    return Float16
  elseif t == UINT8
    return UInt8
  elseif t == INT8
    return Int8
  elseif t == SHORT
    return Int16
  elseif t == INT
    return Int32
  elseif t == LONG
    return Int64
  elseif t == BOOL
    return Bool
  elseif t == BFLOAT16
    return BFloat16
  end
end

function bytewidth(t::DType)
  if t == FLOAT
    return 4
  elseif t == DOUBLE
    return 8
  elseif t == HALF
    return 2
  elseif t == UINT8
    return 1
  elseif t == INT8
    return 1
  elseif t == SHORT
    return 2
  elseif t == INT
    return 4
  elseif t == LONG
    return 8
  elseif t == BOOL
    return 1
  elseif t == BFLOAT16
    return 2
  end
end

function thtype2dtype(defer)
  type = defer.head
  if type == Symbol("torch.FloatStorage")
    return FLOAT
  elseif type == Symbol("torch.DoubleStorage")
    return DOUBLE
  elseif type == Symbol("torch.HalfStorage")
    return HALF
  elseif type == Symbol("torch.ByteStorage")
    return UINT8
  elseif type == Symbol("torch.CharStorage")
    return INT8
  elseif type == Symbol("torch.ShortStorage")
    return SHORT
  elseif type == Symbol("torch.IntStorage")
    return INT
  elseif type == Symbol("torch.LongStorage")
    return LONG
  elseif type == Symbol("torch.BoolStorage")
    return BOOL
  elseif type == Symbol("torch.BFloat16Storage")
    return BFLOAT16
  else
    error("unknown type: $type")
  end
end


mutable struct LazyLoadedStorage{T} <: AbstractVector{T}
    len::Int
    refcnt::Int
    loader::Any
    data::Any
    LazyLoadedStorage{T}(len) where T = new{T}(len, 0)
end
islazy(::LazyLoadedStorage) = true
islazy(x) = false
isloaded(x::LazyLoadedStorage) = isdefined(x, :data)
Base.size(x::LazyLoadedStorage) = (length(x),)
Base.parent(x::LazyLoadedStorage) = x
Base.length(x::LazyLoadedStorage) = x.len
function (v::LazyLoadedStorage)(dest = nothing)
    if isloaded(v)
        isnothing(dest) && return v.data
        @assert dest === v.data "Cannot load to required destination because the storage is already loaded"
        return dest
    end
    if isnothing(dest)
        dest = Array{eltype(v)}(undef, length(v))
    end
    v.loader(dest)
    v.loader = nothing
    v.data = dest
    return dest
end
function Base.show(io::IO, x::LazyLoadedStorage)
    print(io, "LazyLoadedStorage{")
    print(io, eltype(x))
    print(io, "}(loaded = ")
    print(io, isloaded(x))
    print(io, ", len = ")
    print(io, length(x))
    print(io, ')')
end
Base.show(io::IO, ::MIME"text/plain", x::LazyLoadedStorage) = show(io, x)

mutable struct LazyLoadedWrapper{T, N} <: AbstractArray{T, N}
    storage::LazyLoadedStorage{T}
    shape::Dims{N}
    full::Bool
    construct::Any
    data::Any
    function LazyLoadedWrapper{T, N}(storage::LazyLoadedStorage{T}, shape::Dims{N}, construct) where {T, N}
        storage.refcnt += 1
        full = length(storage) == prod(shape)
        if isloaded(storage)
            return new{T, N}(storage, shape, full, construct, construct(storage.data))
        else
            return new{T, N}(storage, shape, full, construct)
        end
    end
end
LazyLoadedWrapper(storage, shape, construct) = LazyLoadedWrapper{eltype(storage), length(shape)}(storage, shape, construct)
islazy(::LazyLoadedWrapper) = true
isloaded(x::LazyLoadedWrapper) = isdefined(x, :data)
function (x::LazyLoadedWrapper)(dest = nothing)
    isloaded(x) && isnothing(dest) && return x.data
    x.storage(dest)
    x.data = x.construct(x.storage.data)
    return x.data
end
function Base.show(io::IO, x::LazyLoadedWrapper)
    print(io, "LazyLoadedWrapper{")
    print(io, eltype(x))
    print(io, "}(loaded = ")
    print(io, isloaded(x))
    print(io, ", size = ")
    print(io, x.shape)
    print(io, ')')
end
Base.show(io::IO, ::MIME"text/plain", x::LazyLoadedWrapper) = show(io, x)

@static if isdefined(Core, :Memory)
    const StorageData = Union{LazyLoadedStorage, Array, Memory}
else
    const StorageData = Union{LazyLoadedStorage, Array}
end

struct StorageManager
  data::Dict{String, Tuple{DType, Int, String, StorageData}}
end

StorageManager() = StorageManager(Dict())
setindex!(sm::StorageManager, value, key) = setindex!(sm.data, value, key)
getindex(sm::StorageManager, key) = getindex(sm.data, key)
haskey(sm::StorageManager, key) = haskey(sm.data, key)
pairs(sm::StorageManager) = pairs(sm.data)
keys(sm::StorageManager) = keys(sm.data)
values(sm::StorageManager) = values(sm.data)

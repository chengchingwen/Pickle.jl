using InternedStrings
using Strided
using ..Pickle: store, save_global, save_get, save_object, memoize, OpCodes, hasref
import ..Pickle: save

const THTensorElType = Union{Float64, Float32, Float16, UInt8,
                             Int8, Int16, Int32, Int16, Bool}

THsave(file::AbstractString, x) = open(file, "w+") do io
  THsave(TorchPickler(), io, x)
end

function THsave(tp::TorchPickler, io, x)
  global MAGIC, TORCH_PROTOCOL
  store(io, MAGIC; proto=protocol(tp))
  store(io, TORCH_PROTOCOL; proto=protocol(tp))
  store(io,
        Dict(
          "little_endian" => Base.ENDIAN_BOM == 0x04030201,
          "protocol_version" => 1001,
          "type_sizes" => Dict(
            "int"=>4,"long"=>4,"short"=>2
          )
        ); proto=protocol(tp))

  store(tp, io, x)
  store(io, collect(keys(tp.storage.data)); proto=protocol(tp))
  write_storage(io, tp.storage)
end

Strided.StridedView(x::PermutedDimsArray{T,N,perm}) where {T,N,perm} = permutedims(StridedView(x.parent), perm)

save(p::TorchPickler, io::IO, a::A) where {T <: THTensorElType, A <: AbstractArray{T}} = save(p, io, StridedView(a))
function save(p::TorchPickler, io::IO, x::S) where {T <: THTensorElType, S <: StridedView{T}}
  save_global(p, io, i"__torch__.rebuild_tensor")

  write(io, OpCodes.MARK)
  save_storage(p, io, x.parent)
  save(p, io, x.offset)
  save_object(p, io, x.size)
  save_object(p, io, x.strides)
  save(p, io, false)
  save_global(p, io, i"OrderedDict")
  write(io, OpCodes.EMPTY_TUPLE)
  write(io, OpCodes.REDUCE)
  write(io, OpCodes.TUPLE)
  write(io, OpCodes.REDUCE)
end

"dummy type for storage type. This is use to inform julia that some arrays are actually the same
 since `objectid` is not consistent on array with same data."
struct StorageTensor{P}
  ptr::P
end

StorageTensor(x::A) where {A<:AbstractArray} = StorageTensor(pointer(x))

function save_storage(p::TorchPickler, io::IO, x::AbstractArray{T}) where T
  s = StorageTensor(x)
  hasref(p.memo, s) && return save_get(p, io, s)

  write(io, OpCodes.MARK)

  save_object(p, io, i"storage")
  save_global(p, io, i"__torch__.StorageType.$T")
  save_object(p, io, string(objectid(x)))
  save_object(p, io, i"cpu")
  save(p, io, length(x))
  save(p, io, nothing)

  write(io, OpCodes.TUPLE)
  write(io, OpCodes.BINPERSID)

  memoize(p, io, s)
  p.storage[string(objectid(x))] = (jltype2dtype(T), length(x), i"cpu", x)

end

function write_storage(io::IO, st::StorageManager)
  for (k, v) in pairs(st.data)
    _, numel, _, storage = v
    write(io, Int64(numel))
    write(io, reinterpret(UInt8, reshape(storage, numel)))
  end
end

function save(p::TorchPickler, io, x::OrderedDict)
  save_global(p, io, i"OrderedDict")
  write(io, OpCodes.EMPTY_TUPLE)
  write(io, OpCodes.REDUCE)

  write(io, OpCodes.MARK)
  for k in keys(x)
    save_object(p, io, k)
    save_object(p, io, x[k])
  end
  write(io, OpCodes.SETITEMS)

  save_object(p, io, Dict(
    "_metadata" => Dict("version"=>1)
  ))

  write(io, OpCodes.BUILD)
  memoize(p, io, x)
end

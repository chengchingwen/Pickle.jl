using ..Pickle: Memo, PickleStack, HierarchicalTable, load, isdefer
using ..Pickle: np_methods!

using Mmap
using DataStructures
using StridedViews
using ZipFile

const DEFAULT_PROTO = 2

const MAGIC = BigInt(0x1950a86a20f9469cfc6c)
const TORCH_PROTOCOL = 1001

struct TorchPickler{PROTO} <: AbstractPickle
  memo::Memo
  stack::PickleStack
  mt::HierarchicalTable
  storage::StorageManager
end

function torch_methods!(st, mt)
    mt["collections.OrderedDict"] = OrderedDict
    mt["torch._utils._rebuild_tensor_v2"] = (arg...) -> build_tensor(st, false, arg...)

    mt["__julia__.__torch__.rebuild_tensor"] = "torch._utils._rebuild_tensor_v2"
    mt["__julia__.OrderedDict"] = "collections.OrderedDict"
    mt["__julia__.__torch__.StorageType.Float32"] = "torch.FloatStorage"
    mt["__julia__.__torch__.StorageType.Float64"] = "torch.DoubleStorage"
    mt["__julia__.__torch__.StorageType.Float16"] = "torch.HalfStorage"
    mt["__julia__.__torch__.StorageType.UInt8"] = "torch.ByteStorage"
    mt["__julia__.__torch__.StorageType.Int8"] = "torch.CharStorage"
    mt["__julia__.__torch__.StorageType.Int16"] = "torch.ShortStorage"
    mt["__julia__.__torch__.StorageType.Int32"] = "torch.IntStorage"
    mt["__julia__.__torch__.StorageType.Int64"] = "torch.LongStorage"
    mt["__julia__.__torch__.StorageType.Bool"] = "torch.BoolStorage"
    mt["__julia__.__torch__.StorageType.BFloat16"] = "torch.BFloat16Storage"

    # ingore state_dict version number
    mt["__build__.OrderedCollections.OrderedDict"] = (od, _meta) -> od
    return mt
end

function TorchPickler(proto=DEFAULT_PROTO, memo=Dict())
  st = StorageManager()
  mt = HierarchicalTable()

  # some corresponding methods
  np_methods!(mt)
  torch_methods!(st, mt)

  TorchPickler{proto}(Memo(memo), PickleStack(), mt, st)
end

protocol(::TorchPickler{P}) where {P} = P
isbinary(pklr::TorchPickler) = protocol(pklr) >= 1

"""
      THload(file::AbstractString; mmap = false, lazy = false)

Load data that saved by `torch.save`. `torch.tensor` will be load as `Array` or `StridedView`
 dependent on the memory layout of that tensor. `mmap` must be set if `lazy` is set. With `lazy = true`,
 each `torch.tensor` will be a lazy object and calling that object (`loaded_lazy_tensor()`) perform the
 actualy load and store the result in that object so subsequent call return the same result.
"""
function THload(file::AbstractString; mmap = false, lazy = false)
    @assert !lazy || mmap "lazy torch loader require mmap=true"
    open(file) do f
        io = mmap ? IOBuffer(Mmap.mmap(f, Vector{UInt8})) : f
        p = TorchPickler()
        if lazy
            mt = p.mt
            st = p.storage
            mt["torch._utils._rebuild_tensor_v2"] = (arg...) -> build_tensor(st, true, arg...)
        end
        return THload(p, io)
    end
end

function THload(tp::TorchPickler, io)
  if peek(io) == 0x80
    return unchecked_legacy_load(tp, io)
  elseif read(io, 4) == b"PK\x03\x04"
    z = ZipFile.Reader(io)
    if any(x->x.name=="constants.pkl", z.files)
      error("TorchScript archive not support.")
    end
    return zip_load(tp, z)
  else
    error("Unkown file format. Is this really a file from `torch.save`?")
  end
end

function get_record(zipfile, name)
  zipfile.files[findfirst(x->endswith(x.name, name), zipfile.files)]
end

function zip_load(tp::TorchPickler, zipfile)
  typeinfo = load(tp, get_record(zipfile, "data.pkl"))
  load_tensor_zip!(zipfile, tp.storage)
  return typeinfo
end

function unchecked_legacy_load(tp::TorchPickler, io)
  magic = load(tp, io)
  magic != MAGIC && error("Invalid magic number; corrupt file?")
  torch_protocol = load(tp, io)
  torch_protocol != TORCH_PROTOCOL && error("Invalid protocol version: $torch_protocol")

  _sys_info = load(tp, io)

  typeinfo = load(tp, io)
  tensor_key = load(tp, io)
  load_tensor!(io, tp.storage, tensor_key)
  return typeinfo
end

function legacy_load(tp::TorchPickler, io)
    typeinfo = unchecked_legacy_load(tp, io)
    @assert !isdefer(typeinfo)
    return typeinfo
end

function build_tensor(sm::StorageManager, lazy, fake_storage, offset, tsize, tstride, grad, _)
    @assert length(tsize) == length(tstride)
    @assert fake_storage.head == :persistent_load
    header, thtype, key, device, numel, = fake_storage.args[1]
    @assert header == "storage"
    dtype = thtype2dtype(thtype)
    jltype = dtype2jltype(dtype)
    tlength = prod(tsize)

    if haskey(sm, key)
        storage = sm[key][end]
    else
        storage = lazy ? LazyLoadedStorage{jltype}(numel) : Array{jltype}(undef, numel)
        setindex!(sm, (dtype, numel, device, storage), key)
    end

    if (tlength == numel) && (isone(length(tsize)) || isempty(tsize) || isone(first(tstride)))
        if lazy
            tensor = LazyLoadedWrapper(storage, tsize, x->Base.ReshapedArray(x, tsize, ()))
        else
            tensor = Base.ReshapedArray(storage, tsize, ()) # f-contiguous
        end
    else # otherwise use strided
        if lazy
            tensor = LazyLoadedWrapper(storage, tsize, x->StridedView(x, tsize, tstride, offset))
        else
            tensor = StridedView(storage, tsize, tstride, offset)
        end
    end

    return tensor
end

function load_tensor!(io::IO, sm::StorageManager, tensor_key)
    for key in tensor_key
        type, numel, device, storage = sm[key]
        tsize = read(io, Int64)
        @assert tsize == numel
        nbytes = tsize * bytewidth(type)
        if storage isa LazyLoadedStorage
            start = io.ptr
            tdata = @view io.data[start:start+nbytes-1]
            storage.loader = dest -> dest .= reinterpret(dtype2jltype(type), tdata)
            io.ptr += nbytes
        else
            @assert storage isa Array && nbytes == sizeof(storage)
            read!(io, storage)
        end
    end
end

function load_tensor_zip!(zipfile, sm::StorageManager)
    for (key, values) in pairs(sm)
        type, numel, device, storage = values
        if storage isa LazyLoadedStorage
            storage.loader = function (dest)
                zf = get_record(zipfile, "/$key")
                T = dtype2jltype(type)
                if dest isa Array{T}
                    @assert numel == length(dest)
                    buf = unsafe_wrap(Array, convert(Ptr{T}, pointer(dest)), numel)
                    GC.@preserve dest read!(zf, buf)
                else
                    tdata = read(zf)
                    dest .= reinterpret(dtype2jltype(type), tdata)
                end
                return dest
            end
        else
            zf = get_record(zipfile, "/$key")
            T = dtype2jltype(type)
            @assert numel == length(storage)
            buf = unsafe_wrap(Array, convert(Ptr{T}, pointer(storage)), numel)
            GC.@preserve storage read!(zf, buf)
        end
    end
end

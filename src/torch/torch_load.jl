using ..Pickle: Memo, PickleStack, HierarchicalTable, load, isdefer

using DataStructures
using Strided

const DEFAULT_PROTO = 2

const MAGIC = BigInt(0x1950a86a20f9469cfc6c)
const TORCH_PROTOCAL = 1001

struct TorchPickler{PROTO} <: AbstractPickle
  memo::Memo
  stack::PickleStack
  mt::HierarchicalTable
  storage::StorageManager
end

function TorchPickler(proto=DEFAULT_PROTO, memo=Dict())
  st = StorageManager()
  mt = HierarchicalTable()

  # some corresponding methods
  mt["collections.OrderedDict"] = OrderedDict
  mt["torch._utils._rebuild_tensor_v2"] = (arg...) -> build_tensor(st, arg...)
  # ingore state_dict version number
  mt["__build__.OrderedCollections.OrderedDict"] = (od, _meta) -> od

  TorchPickler{proto}(Memo(memo), PickleStack(), mt, st)
end

protocal(::TorchPickler{P}) where {P} = P
isbinary(pklr::TorchPickler) = protocal(pklr) >= 1

THload(file::AbstractString) = open(file) do io
  THload(TorchPickler(), io)
end

function THload(tp::TorchPickler, io)
  magic = load(tp, io)
  magic != MAGIC && error("Invalid magic number; corrupt file?")
  torch_protocal = load(tp, io)
  torch_protocal != TORCH_PROTOCAL && error("Invalid protocol version: $torch_protocal")

  _sys_info = load(tp, io)

  typeinfo = load(tp, io)
  tensor_key = load(tp, io)
  tensor_data = load_tensor(io, tp.storage, tensor_key)
  @assert !isdefer(typeinfo)
  return typeinfo
end

function build_tensor(sm::StorageManager, fake_storage, offset, tsize, tstride, grad, _)
  @assert length(tsize) == length(tstride)
  @assert fake_storage.head == :persistent_load
  header, thtype, key, device, numel, _ = fake_storage.args[1]
  @assert header == "storage"
  dtype = thtype2dtype(thtype)
  jltype = dtype2jltype(dtype)
  tlength = prod(tsize)

  if haskey(sm, key)
    storage = sm[key][end]
  else
    storage = Array{jltype}(undef, numel)
    setindex!(sm, (dtype, numel, device, storage), key)
  end

  if (tlength == numel) && (isone(length(tsize)) || isone(first(tstride)))
    tensor = reshape(storage, tsize) # f-contiguous
  else # otherwise use strided
    tensor = StridedView(storage, tsize, tstride, offset)
  end

  return tensor
end

function load_tensor(io::IO, sm::StorageManager, tensor_key)
  for key in tensor_key
    type, numel, device, storage = sm[key]
    tsize = read(io, Int64)
    @assert tsize == numel
    tdata = read(io, tsize * bytewidth(type))
    storage .= reinterpret(dtype2jltype(type), tdata)
  end
end

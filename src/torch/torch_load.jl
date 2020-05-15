using ..Pickle: Memo, PickleStack, HierarchicalTable, load

using .Storage: STORAGE, bitwidth, jtype

using DataStructures

const DEFAULT_PROTO = 2

const MAGIC = BigInt(0x1950a86a20f9469cfc6c)
const TORCH_PROTOCAL = 1001

struct TorchPickler{PROTO} <: AbstractPickle
  memo::Memo
  stack::PickleStack
  mt::HierarchicalTable
end

TorchPickler(proto=DEFAULT_PROTO, memo=Dict()) =
  TorchPickler{proto}(Memo(memo), PickleStack(), THmt())

function THmt()
  mt = HierarchicalTable()
  mt["collections.OrderedDict"] = OrderedDict
  mt["__main__.persistent_load"] = Storage.persistent_load
  mt
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
  tensor_data = load_tensor(io, tensor_key)

  build_state(typeinfo, tensor_data)
end

function load_tensor(io::IO, tensor_key)
  global STORAGE
  tensor_data = Dict{String, Array}()
  for key in tensor_key
    type = STORAGE[key][1]
    tsize = read(io, Int64)
    tdata = read(io, tsize * bitwidth(type))
    tensor_data[key] = reinterpret(jtype(type), tdata)
  end
  empty!(Storage.STORAGE.data)
  return tensor_data
end

function build_state(typeinfo, tensor_data)
  state = typeinfo.args[1]
  for (key, value) in pairs(state)
    state[key] = buildtensor(tensor_data, value)
  end
  return state
end

function buildtensor(tensor_data, value)
  @assert value.head == :reduce
  f, key, offset, tsize, tstride, grad, _ = value.args
  @assert f.head == Symbol("torch._utils._rebuild_tensor_v2")
  _tensor = tensor_data[key]
  if iszero(offset)
    if length(tstride) > 1
      if isone(tstride[end])
        # @info "row major: $key"
        tensor = similar(_tensor, reverse(tsize))
        permutedims!(tensor, reshape(_tensor, tsize), length(tstride):-1:1)
      elseif isone(tstride[1])
        # @info "column major: $key"
        tensor = reshape(_tensor, tsize)
      else
        error("unknown stride strategy: $tstride")
      end
    else
      tensor = _tensor
    end
  else
    error("array view not handled")
    # tensor = unsafe_wrap(Array{eltype(_tensor), length(tsize)},
    #             pointer(tensor) + offset*sizeof(eltype(_tensor)),
    #             tsize)
  end
  return tensor
end

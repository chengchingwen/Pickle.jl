using ..Pickle: Memo, PickleStack, HierarchicalTable, load

using DataStructures

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

  mt["collections.OrderedDict"] = OrderedDict
  #mt["__main__.persistent_load"] = Storage.persistent_load
  mt["torch._utils._rebuild_tensor_v2"] = (arg...) -> build_tensor(st, arg...)
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

  # build_state(typeinfo, tensor_data)
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

  if iszero(offset) # no offset
    if isone(length(tsize)) # 1-D
      if numel == tlength # same
        tensor = storage
      else # subarray
        stride1 = first(tstride)
        bound = stride1 * tlength
        indices = 1:stride1:bound
        tensor = @view storage[indices]
        # if isone(first(tstride)) # contiguous
        #   tensor = unsafe_wrap(
        #     Vector{jltype},
        #     pointer(storage),
        #     tsize)
        # else # non-contiguous
        #   stride1 = first(tstride)
        #   bound = stride1 * tlength
        #   tensor = @view storage[1:stride1:bound]
        #   @assert length(tensor) == tlength
        # end
      end
    else # N-D
      if numel == tlength # same
        if isone(first(tstride)) # f-contiguous
          tensor = reshape(storage, tsize)
          # tensor = unsafe_wrap(
          #   Array{jltype, length(tsize)},
          #   pointer(storage),
          #   tsize)
        elseif isone(last(tstride)) # c-contiguous
          tensor = reshape(storage, reverse(tsize))
          # tensor = PermutedDimsArray(
          #   reshape(storage, reverse(tsize)),
          #   length(tstride):-1:1)
        else
          error("unkown array major")
        end
      else # subarray
        #TODO
        rang = Iterators.product(map(x->0:x-1, tsize)...)
        tensor = @view storage[map(x->sum(x .* tstride) + 1, rang)]
      end
    end
  else # offset array
    stlength = numel - offset # reset length of storage
    _storage = unsafe_wrap(
      Vector{jltype},
      pointer(storage) +
      offset*sizeof(jltype),
      (stlength,))

    if isone(length(tsize)) # 1-D
      stride1 = first(tstride)
      bound = stride1 * tlength
      indices = (1+offset):stride1:(offset+bound)
      tensor = @view storage[indices]
    else # N-D
      if tlength == stlength # take all
        tensor = reshape(_storage, tsize)
      else # subarray
        rang = Iterators.product(map(x->0:x-1, tsize)...)
        tensor = @view storage[map(x->sum(x .* tstride) + 1 + offset, rang)]
      end
    end
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

# function build_state(typeinfo, tensor_data)
#   state = typeinfo.args[1]
#   for (key, value) in pairs(state)
#     state[key] = buildtensor(tensor_data, value)
#   end
#   return state
# end

# function buildtensor(storage, offset, tsize, tstride, grad, _)
#   if iszero(offset)
#     if length(tstride) > 1
#       if isone(tstride[end])
#         # @info "row major: $key"
#         tensor = similar(_tensor, reverse(tsize))
#         permutedims!(tensor, reshape(_tensor, tsize), length(tstride):-1:1)
#       elseif isone(tstride[1])
#         # @info "column major: $key"
#         tensor = reshape(_tensor, tsize)
#       else
#         error("unknown stride strategy: $tstride")
#       end
#     else
#       tensor = _tensor
#     end
#   else
#     error("array view not handled")
#     # tensor = unsafe_wrap(Array{eltype(_tensor), length(tsize)},
#     #             pointer(tensor) + offset*sizeof(eltype(_tensor)),
#     #             tsize)
#   end
#   return tensor

# end


# function buildtensor(tensor_data, value)
#   @assert value.head == :reduce
#   f, key, offset, tsize, tstride, grad, _ = value.args
#   @assert f.head == Symbol("torch._utils._rebuild_tensor_v2")
#   _tensor = tensor_data[key]
#   if iszero(offset)
#     if length(tstride) > 1
#       if isone(tstride[end])
#         # @info "row major: $key"
#         tensor = similar(_tensor, reverse(tsize))
#         permutedims!(tensor, reshape(_tensor, tsize), length(tstride):-1:1)
#       elseif isone(tstride[1])
#         # @info "column major: $key"
#         tensor = reshape(_tensor, tsize)
#       else
#         error("unknown stride strategy: $tstride")
#       end
#     else
#       tensor = _tensor
#     end
#   else
#     error("array view not handled")
#    # tensor = unsafe_wrap(Array{eltype(_tensor), length(tsize)},
#    #             pointer(tensor) + offset*sizeof(eltype(_tensor)),
#    #             tsize)
#   end
#   return tensor
# end

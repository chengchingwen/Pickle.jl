struct NpyPickler{PROTO} <: AbstractPickle
  memo::Memo
  stack::PickleStack
  mt::HierarchicalTable
end

function NpyPickler(proto=DEFAULT_PROTO, memo=Dict())
  mt = HierarchicalTable()
  mt["numpy.core.multiarray._reconstruct"] = np_multiarray_reconstruct
  mt["numpy.dtype"] = np_dtype
  mt["__build__.Pickle.NpyDtype"] = build_npydtype
  mt["__build__.NpyDtype"] = build_npydtype
  mt["__build__.Pickle.NpyArrayPlaceholder"] = build_nparray
  mt["__build__.NpyArrayPlaceholder"] = build_nparray

  return Pickler{proto}(Memo(memo), PickleStack(), mt)
end

npyload(f::AbstractString) = load(NpyPickler(), f)

struct NpyArrayPlaceholder end

function np_multiarray_reconstruct(subtype, shape, dtype)
    @assert subtype.head == Symbol("numpy.ndarray")
    @assert isempty(subtype.args)
    @assert shape == (0,)
    @assert dtype == b"b"
    return NpyArrayPlaceholder()
end

struct NpyDtype{T}
    little_endian::Bool
    dstring::String
    align::Bool
    copy::Bool
end

Base.eltype(::NpyDtype{T}) where T = T

function npy_typechar_to_jltype(t, n)
    if t in ("?", "b", "B")
        @assert isempty(n) || n == "1"
    end
    n = tryparse(Int, n)
    n = (isnothing(n) ? 4 : n) * 8
    @assert n in (8, 16, 32, 64, 128)

    if t == "?"
        return Bool
    elseif t == "b"
        return Int8
    elseif t == "B"
        return UInt8
    elseif t == "i"
        if n == 8
            return Int8
        elseif n == 16
            return Int16
        elseif n == 32
            return Int32
        elseif n == 64
            return Int64
        elseif n == 128
            return Int128
        else
            error("unsupport length $n for $t")
        end
    elseif t == "u"
        if n == 8
            return UInt8
        elseif n == 16
            return UInt16
        elseif n == 32
            return UInt32
        elseif n == 64
            return UInt64
        elseif n == 128
            return UInt128
        else
            error("unsupport length $n for $t")
        end
    elseif t == "f"
        if n == 16
            return Float16
        elseif n == 32
            return Float32
        elseif n == 64
            return Float64
        else
            error("unsupport length $n for $t")
        end
    else
        error("unsupport type $t")
    end
end


# TODO: handle dtype comprehensively
# https://github.com/numpy/numpy/blob/eeef9d4646103c3b1afd3085f1393f2b3f9575b2/numpy/core/src/multiarray/descriptor.c#L2442
function np_dtype(obj, align, copy)
    align, copy = Bool(align), Bool(copy)
    @assert !align "structure dtype disallow"
    @assert copy
    m = match(r"^([<=>])?([?bBiuf])(\d*)$", obj)
    @assert !isnothing(m) "unsupported dtype $obj: consider file an issue"
    ei, t, n = m.captures
    # '>': big, '<': little, '=': hardware-native
    islittle = ei == ">" ? false : ei == "<" ? true : islittle_endian()
    T = npy_typechar_to_jltype(t, n)
    return NpyDtype{T}(islittle, obj, align, copy)
end

function build_npydtype(npydtype, state)
    metadata = length(state) == 9 ? state[9] : nothing
    ver, ei, sub_descrip, _names, _fields, elsize, alignment, flags = state

    @assert isnothing(sub_descrip)
    @assert isnothing(_names)
    @assert isnothing(_fields)
    @assert elsize == -1
    @assert alignment == -1
    @assert flags == 0
    # '>': big, '<': little, '=': hardware-native
    islittle = ei == ">" ? false : ei == "<" ? true : islittle_endian()
    return NpyDtype{eltype(npydtype)}(islittle, npydtype.dstring, npydtype.align, npydtype.copy)
end

c2f(arr, shape) = PermutedDimsArray(reshape(arr, reverse(shape)), reverse(ntuple(identity, length(shape))))

# https://github.com/numpy/numpy/blob/6568c6b022e12ab6d71e7548314009ced6ccabe9/numpy/core/src/multiarray/methods.c#L1711
# TODO: support picklebuffer (Pickle v5)
function build_nparray(_, args)
    ver, shp, dtype, is_column_maj, data = args
    _arr = reinterpret(eltype(dtype), data)
    arr = is_column_maj ? reshape(_arr, shp) : c2f(_arr, shp)
    return dtype.little_endian ? Base.ltoh.(arr) : Base.ntoh.(arr)
end


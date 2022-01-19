struct NpyPickler{PROTO} <: AbstractPickle
  memo::Memo
  stack::PickleStack
  mt::HierarchicalTable
end

function np_methods!(mt)
  mt["numpy.core.multiarray._reconstruct"] = np_multiarray_reconstruct
  mt["numpy.dtype"] = np_dtype
  mt["numpy.core.multiarray.scalar"] = np_scalar
  mt["__build__.Pickle.NpyDtype"] = build_npydtype
  mt["__build__.Pickle.NpyArrayPlaceholder"] = build_nparray
  mt["scipy.sparse.csr.csr_matrix"] = sparse_matrix_reconstruct
  mt["__build__.Pickle.SpMatrixPlaceholder"] = build_spmatrix
  return mt
end

function NpyPickler(proto=DEFAULT_PROTO, memo=Dict())
  mt = HierarchicalTable()
  np_methods!(mt)
  return Pickler{proto}(Memo(memo), PickleStack(), mt)
end

npyload(f) = load(NpyPickler(), f)

struct NpyArrayPlaceholder end

function np_multiarray_reconstruct(subtype, shape, dtype)
    @assert subtype.head == Symbol("numpy.ndarray")
    @assert isempty(subtype.args)
    @assert shape == (0,)
    @assert dtype == b"b" || dtype == "b"
    return NpyArrayPlaceholder()
end

struct SpMatrixPlaceholder end

sparse_matrix_reconstruct() = SpMatrixPlaceholder()

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

struct NString{N} end

slen(::NString{N}) where N = N

# TODO: handle dtype comprehensively
# https://github.com/numpy/numpy/blob/eeef9d4646103c3b1afd3085f1393f2b3f9575b2/numpy/core/src/multiarray/descriptor.c#L2442
function np_dtype(obj, align, copy)
    align, copy = Bool(align), Bool(copy)
    @assert !align "structure dtype disallow"
    @assert copy
    m = match(r"^([<=>])?([?bBiufU])(\d*)$", obj)
    if isnothing(m)
        @warn "unsupported dtype $obj: consider file an issue"
        return Defer(Symbol("numpy.dtype"), obj, align, copy)
    end

    ei, t, n = m.captures
    # '>': big, '<': little, '=': hardware-native
    islittle = ei == ">" ? false : ei == "<" ? true : islittle_endian()
    if t == "U"
        n = tryparse(Int, n)
        T = NString{isnothing(n) ? 1 : n}()
    else
        T = npy_typechar_to_jltype(t, n)
    end
    return NpyDtype{T}(islittle, obj, align, copy)
end

function build_npydtype(npydtype, state)
    metadata = length(state) == 9 ? state[9] : nothing
    ver, ei, sub_descrip, _names, _fields, elsize, alignment, flags = state

    T = eltype(npydtype)
    @assert isnothing(sub_descrip)
    @assert isnothing(_names)
    @assert isnothing(_fields)
    if T isa NString
        n = slen(T)
        @assert elsize == 4n
        @assert alignment == 4
        @assert flags == 8
    else
        @assert elsize == -1
        @assert alignment == -1
        @assert flags == 0
    end
    # '>': big, '<': little, '=': hardware-native
    islittle = ei == ">" ? false : ei == "<" ? true : islittle_endian()
    return NpyDtype{T}(islittle, npydtype.dstring, npydtype.align, npydtype.copy)
end

c2f(arr, shape) = PermutedDimsArray(reshape(arr, reverse(shape)), reverse(ntuple(identity, length(shape))))
c2f(arr, shape, n) = c2f(arr, (shape..., n))

function nstring(cs)
    i = findfirst(isequal('\0'), cs)
    return isnothing(i) ? String(cs) : String(@view(cs[1:i-1]))
end

# https://github.com/numpy/numpy/blob/6568c6b022e12ab6d71e7548314009ced6ccabe9/numpy/core/src/multiarray/methods.c#L1711
# TODO: support picklebuffer (Pickle v5)
function build_nparray(_, args)
    ver, shp, dtype, is_column_maj, data = args
    if dtype isa Defer
        return Defer(Symbol("build.nparray"), args)
    end
    T = eltype(dtype)

    data = data isa String ? codeunits(data) : data # old numpy use string instead of bytes

    if T isa NString
        n = slen(T)
        _data = reinterpret(UInt32, data)
        _arr = dtype.little_endian ? Char.(Base.ltoh.(_data)) : Char.(Base.ntoh.(_data))
        arr = is_column_maj ? reshape(_arr, n, shp...) : c2f(_arr, shp, n)
        return reshape(mapslices(nstring, arr; dims=ndims(arr)), shp)
    else
        _data = reinterpret(T, data)
        _arr = dtype.little_endian ? Base.ltoh.(_data) : Base.ntoh.(_data)
        arr = is_column_maj ? reshape(_arr, shp) : c2f(_arr, shp)
        return collect(arr)
    end
end

function np_scalar(dtype, data)
    T = eltype(dtype)
    if T isa NString
        n = slen(T)
        _data = reinterpret(UInt32, data)
        _arr = dtype.little_endian ? Char.(Base.ltoh.(_data)) : Char.(Base.ntoh.(_data))
        return String(_arr)
    else
        _data = reinterpret(T, data)
        _arr = dtype.little_endian ? Base.ltoh.(_data) : Base.ntoh.(_data)
        return _arr[]
    end
end

function build_spmatrix(_, args)
    shape = args["_shape"]
    nzval, colptr, rowval = csr_to_csc(shape..., args["data"], args["indptr"] .+ 1, args["indices"] .+ 1)
    return SparseArrays.SparseMatrixCSC(shape..., colptr, rowval, nzval)
end

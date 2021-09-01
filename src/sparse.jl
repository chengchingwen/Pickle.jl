getptr(ptr::AbstractVector, i::Integer) = ptr[i]:(ptr[i+1]-1)
nptr(ptr::AbstractVector, i::Integer) = length(getptr(ptr, i))

"""
    csr_to_csc(nrow, ncol, nz, rowptr, colval)

Convert the sparse matrix CSR format to CSC format and it returns `new_nz`, `colptr`, `rowval`.

# Arguments

- `nrow::Integer`: Number of rows
- `ncol::Integer`: Number of columns.
- `nz::AbstractVector`: Nonzero elements.
- `rowptr::AbstractVector`: Row pointers.
- `colval::AbstractVector`: Column indices.

Ref: https://github.com/scipy/scipy/blob/3b36a574dc657d1ca116f6e230be694f3de31afc/scipy/sparse/sparsetools/csr.h#L380
"""
function csr_to_csc(nrow::Integer, ncol::Integer, nz::AbstractVector, rowptr::AbstractVector{T}, colval::AbstractVector{T}) where {T<:Integer}
    nnz = rowptr[end] - 1
    new_nz = similar(nz)
    rowval = similar(colval)

    # calculate number of nonzero elements in each column, O(nnz)
    colptr = zeros(T, ncol+1)
    for i in 1:nnz
        colptr[colval[i]] += one(T)
    end

    # calculate offsets, O(ncol)
    cumsum = one(T)
    for j in 1:ncol
        temp = colptr[j]
        colptr[j] = cumsum
        cumsum += temp
    end
    colptr[end] = nnz

    # calculate index, O(nnz)
    for i in 1:nrow
        for jj in getptr(rowptr, i)
            j = colval[jj]
            dest = colptr[j]

            rowval[dest] = i
            new_nz[dest] = nz[jj]

            colptr[j] += 1
        end
    end

    # calculate offsets, O(ncol)
    last = one(T)
    for j in 1:(ncol+1)
        colptr[j], last = last, colptr[j]
    end
    return new_nz, colptr, rowval
end


# SparseMatrixCSC(defer.args[2]["_shape"]..., defer.args[2]["indptr"] .+ 1, defer.args[2]["indices"] .+ 1, defer.args[2]["data"])
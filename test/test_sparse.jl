@testset "sparse" begin
    @testset "conversion" begin
        nrow = 4
        ncol = 5
        nnz = 7
        mat = [0 1 4 0 0;
            0 0 0 0 0;
            0 2 0 6 0;
            0 3 5 7 0]

        csr_rowptr = [1, 3, 3, 5, 8]
        csr_col = [2, 3, 2, 4, 2, 3, 4]
        csr_nzv = [1, 4, 2, 6, 3, 5, 7]

        csc_colptr = [1, 1, 4, 6, 8, 8]
        csc_row = [1, 3, 4, 1, 4, 3, 4]
        csc_nzv = collect(1:nnz)

        nzval, colptr, row = Pickle.csr_to_csc(nrow, ncol, csr_nzv, csr_rowptr, csr_col)
        @test colptr == csc_colptr
        @test row == csc_row
        @test nzval == csc_nzv
    end

    @testset "load" begin
        spA = SparseMatrixCSC(Array(to_nparray(pyload("./test_pkl/csr_mat.pkl"))))
        @test Pickle.npyload("./test_pkl/csr_mat.pkl") == spA
    end
end

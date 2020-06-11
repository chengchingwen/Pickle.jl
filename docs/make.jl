using Documenter, Pickle

makedocs(sitename="Pickle.jl",
         pages = Any[
           "Home"=>"index.md",
           "Internal"=>Any[
             "Stack Machine"=>"stack.md",
             "OpCodes"=>"opcode.md",
           ]
         ],
         )

deploydocs(
    repo = "github.com/chengchingwen/Pickle.jl.git",
)

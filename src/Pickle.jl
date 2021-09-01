module Pickle

import Serialization
using Serialization: AbstractSerializer

using DataStructures

if VERSION < v"1.1"
    isnothing(::Nothing) = true
    isnothing(::Any) = false
end

islittle_endian() = Base.ENDIAN_BOM == 0x04030201

export load, store, loads, stores, AbstractPickle, Pickler

include("./readarg.jl")
include("./writearg.jl")
include("./opcode/opcode.jl")
using .OpCodes

include("./defaults.jl")
include("./mt_table.jl")

import Base: push!, pop!, first, isempty, show, setindex!, getindex, length

struct PickleStack
  meta::Stack{Stack{Any}}
end

function PickleStack()
  meta = Stack{Stack{Any}}()
  s = PickleStack(meta)
  mark!(s)
	return s
end

getstack(s::PickleStack) = first(s.meta)
@inline isempty(s::PickleStack) = isempty(getstack(s))
@inline push!(s::PickleStack, @nospecialize(x)) = push!(getstack(s), x)
@inline pop!(s::PickleStack) = pop!(getstack(s))
@inline pop2!(s::PickleStack) = (pop!(s), pop!(s))
@inline pop3!(s::PickleStack) = (pop!(s), pop!(s), pop!(s))
@inline first(s::PickleStack) = first(getstack(s))
@inline mark!(s::PickleStack) = push!(s.meta, Stack{Any}())
@inline unmark!(s::PickleStack) = reverse!(collect(pop!(s.meta)))
@inline updatefirst!(s::PickleStack, @nospecialize(x)) = (pop!(s); push!(s, x))
@inline maybeupdatefirst!(s::PickleStack, @nospecialize(x)) =
  objectid(first(s)) == objectid(x) ? nothing : updatefirst!(s, x)

struct Memo
  data::Dict{Int, Any}
  ref::IdDict{Any, Int}
end

function Memo(data)
  ref = IdDict{Any, Int}()
  for (k, v) in data
    ref[v] = k
  end
  return Memo(data, ref)
end

function setindex!(m::Memo, @nospecialize(value), key)
  setindex!(m.ref, key, value)
  setindex!(m.data, value, key)
end

length(m::Memo) = length(m.data)
getindex(m::Memo, key) = getindex(m.data, key)
hasref(m::Memo, @nospecialize(key)) = haskey(m.ref, key)
getref(m::Memo, @nospecialize(key)) = getindex(m.ref, key)

@inline function maybeupdate!(m::Memo, key, value)
  @nospecialize key value
  objectid(key) == objectid(value) ? nothing : update!(m, key, value)
end

@inline function update!(m::Memo, key, value)
  @nospecialize key value
  mid = m.ref[key]
  objectid(key) != objectid(value) && delete!(m.ref, key)
  setindex!(m, value, mid)
end

abstract type AbstractPickle <: AbstractSerializer end

"default pickle protocol version"
const DEFAULT_PROTO = 4

struct Pickler{PROTO} <: AbstractPickle
  memo::Memo
  stack::PickleStack
  mt::HierarchicalTable
end

function Pickler(proto=DEFAULT_PROTO, memo=Dict())
  mt = HierarchicalTable()
  Pickler{proto}(Memo(memo), PickleStack(), mt)
end

protocol(::Pickler{P}) where {P} = P
isbinary(pklr::Pickler) = protocol(pklr) >= 1

include("./deserializer.jl")
include("./serializer.jl")

# numpy hack
include("./np.jl")
include("sparse.jl")

include("./torch/torch.jl")
using .Torch

end # module

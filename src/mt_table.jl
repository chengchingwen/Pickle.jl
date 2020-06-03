import Base: setindex!, haskey, getindex

struct TableBlock
  depth::Int
  entry::Dict{String, Union{TableBlock, Some}}
end

TableBlock() = TableBlock(0)
TableBlock(depth) = TableBlock(depth, Dict())

@inline haskey(tb::TableBlock, x) = haskey(tb.entry, x)

function _setentry!(tb::TableBlock, value::Some, key; maxdepth=typemax(Int))
  (haskey(tb, key) || !any(isequal('.'), key) || tb.depth >= maxdepth) &&
    return setindex!(tb.entry, value, key)

  scope, id = split(key, '.'; limit=2)

  ctb = haskey(tb, scope) ? tb.entry[scope] : begin
    _ctb = TableBlock(tb.depth+1)
    setindex!(tb.entry, _ctb, scope)
    _ctb
  end
  return _setentry!(ctb, value, id)
end

function _getentry(tb::TableBlock, key; maxdepth=typemax(Int), error=false)
  (haskey(tb, key) || !any(isequal('.'), key) || tb.depth >= maxdepth) &&
    (error ? (return getindex(tb.entry, key)) : (return get(tb.entry, key, nothing)))

  scope, id = split(key, '.'; limit=2)

  if !haskey(tb, scope)
    error ? throw(KeyError(scope)) : return nothing
  else
    ctb = tb.entry[scope]
    !(ctb isa TableBlock) && (error ? throw(KeyError(scope)) : return nothing)
    return _getentry(ctb, id)
  end
end

struct HierarchicalTable
  maxdepth::Int
  head::TableBlock
end

HierarchicalTable() = HierarchicalTable(typemax(Int))
HierarchicalTable(maxdepth) = HierarchicalTable(maxdepth, TableBlock())

setindex!(ht::HierarchicalTable, value, key) = _setentry!(ht.head, Some(value), key; maxdepth=ht.maxdepth)

getindex(ht::HierarchicalTable, key) = something(_getentry(ht.head, key; maxdepth=ht.maxdepth, error=true))

haskey(ht::HierarchicalTable, key) = !isnothing(_getentry(ht.head, key))

const GLOBAL_MT = HierarchicalTable()

lookup(mt::HierarchicalTable, scope, name) = lookup(mt, join((scope, name), '.'))
function lookup(mt::HierarchicalTable, key)
  global GLOBAL_MT
  mtv = _getentry(mt.head, key)
  if isnothing(mtv)
    gmtv = _getentry(GLOBAL_MT.head, key)
    return isnothing(gmtv) ? gmtv : something(gmtv)
  else
    return something(mtv)
  end
end

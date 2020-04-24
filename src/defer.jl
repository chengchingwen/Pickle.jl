struct Defer{F}
  f::F
  name::String
end

Defer(name::String) = Base.Fix2(Defer, name)

function Base.show(io::IO, def::Defer)
  print(io, "<Deferred $(def.name)>")
end

macro defer(name, block)
  return quote
    Defer($(esc(name))) do
      $(esc(block))
    end
  end
end

_get(def::Defer) = def.f()
_get(x) = x
_get(arr::Union{Array, Tuple, NTuple}) = isdefer(arr) ? map(_get, arr) : arr
_get(nd::NamedTuple) = isdefer(nd) ? NamedTuple{keys(nd)}(map(_get, values(nd))) : nd
_get(p::Pair) = isdefer(p) ? _get(p[0])=>_get(p[1]) : p
_get(dict::Dict) = isdefer(dict) ? Dict(_get(k)=>_get(v) for (k, v) in dict) : dict

(def::Defer)() = _get(def)

isdefer(::Defer) = true
isdefer(x) = false
isdefer(arr::Union{Array, Tuple, NTuple}) = any(isdefer, arr)
isdefer(nd::NamedTuple) = any(isdefer, values(nd))
isdefer(p::Pair) = isdefer(p[1]) || isdefer(p[2])
isdefer(dict::Dict) = any(isdefer, pairs(dict))

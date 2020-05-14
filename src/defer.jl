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

struct DeferFunc{F}
  f::F
  md::String
  fn::String
  defer::Bool
end

isdefer(df::DeferFunc) = true
_get(df::DeferFunc) = (global mt_table; isnothing(df) ? mt_table[(df.md, df.fn)] : df.f)

function Base.show(io::IO, df::DeferFunc)
  print(io, "<$( isnothing(df.f) ? "Deferred " : "")Func $(df.md).$(df.fn)>")
end

function (df::DeferFunc)(args...; kwargs...)
  global mt_table
  md, fn, defer = df.md, df.fn, df.defer
  @info "calling $(md).$(fn)($(join(args, ", ")); $(join(kwargs, ", ")))"
  real_fn = df.f
  if isnothing(real_fn)
    if defer
      @warn "$(md).$(fn) is not defined in `mt_table`. deferring function call."
      return @defer join((md, fn), '.') mt_table[(md, fn)](_get(args)..., _get(kwargs)...)
    else
      error("$(md).$(fn) is not defined in `mt_table`.")
    end
  elseif isdefer(args) || isdefer(kwargs)
    @warn "deferring call"
    return @defer join((md, fn), '.') real_fn(_get(args)..., _get(kwargs)...)
  else
    return real_fn(args...; kwargs...)
  end
end

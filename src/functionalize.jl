###############################
# functionalize
###############################
struct _functionalize{F} <: Function; f::F; end
@inline (f::_functionalize)(a...; ka...) = f.f(a...; ka...)

@inline functionalize(f) = _functionalize(f)
# functionalize(f) = f
@inline functionalize(f::Function) = f
@inline functionalize(s::Symbol) = o -> getproperty(o, s)
@inline functionalize(s::Union{Tuple, AbstractArray, Base.Generator}) =
    (a...; ka...) -> map(f->functionalize(f)(a...; ka...), s)
@inline functionalize(s::NamedTuple) =
    (a...; ka...) -> map(f->functionalize(f)(a...; ka...), values(s))

###############################
# arg
###############################

struct Args <: Function
    a
    ka
end

@inline (a::Args)(f) = functionalize(f)(a.a...; a.ka...)

@inline arg(a...; ka...) = Args(a, ka)

###############################
# _grb, _get, _mthd, _set, _gets, _sets
###############################

#=
x |> _grb.a = x.a
x |> _grb[10] = x[10]
x |> _grb.a[10] = x.a[10]
x |> _grb("a") = x.a
x |> _grb(:a) = x.a

x |> _get.a == x.a
x |> _get[10,3] == x[10,3]
x |> _get.a[1:10,4:5] == x.a[1:10,4:5]

x |> _mthd.a(10) == x.a(10)
x |> _mthd[10](3) == x[10](3)
x |> _mthd.a[10](3) == x.a[10](3)

x |> _set.a(3) ===> (x.a = 3; x)
x |> _set.a[10](3) ===> (x.a[10] = 3; x)
x |> _set[10](3) ===> (x[10] = 3; x)
x |> _set(:a)(3) ===> (x.a = 3; x)

x |> _gets[:a, 3] ===> [x.a, x[3]]
x |> _sets[:a, 3](10, 20) ===> (x.a = 10; x[3] = 20; x)
=#

struct _GetSingleton end
const _get = _GetSingleton()

struct _GrbSingleton end
const _grb = _GrbSingleton()
(s::_GrbSingleton)(atr::Symbol) = Base.getproperty(s, atr)
(s::_GrbSingleton)(atr::AbstractString) = s(Symbol(atr))

struct _MthdSingleton end
const _mthd = _MthdSingleton()

struct _SetSingleton end
const _set = _SetSingleton()
(::_SetSingleton)(atr::Symbol) = x -> (o -> Base.setproperty!(o, atr, x))
(s::_SetSingleton)(atr::AbstractString) = s(Symbol(atr))

struct _GetsSingleton end
const _gets = _GetsSingleton()

struct _SetsSingleton end
const _sets = _SetsSingleton()

abstract type _AbstGet <: Function end

mutable struct _Grb <: _AbstGet
    __itms::Vector{Any}
end

mutable struct _Get <: _AbstGet
    __itms::Vector{Any}
end

mutable struct _Mthd <: _AbstGet
    __itms::Vector{Any}
end

mutable struct _Set <: _AbstGet
    __itms::Vector{Any}
end

mutable struct _Gets <: _AbstGet
    __itms::Tuple
end

mutable struct _Sets <: _AbstGet
    __itms::Tuple
end

Base.getproperty(g::_GrbSingleton, a::Symbol) = _Grb([a])
Base.getindex(g::_GrbSingleton, a...) = _Grb([a])

Base.getproperty(g::_GetSingleton, a::Symbol) = _Get([a])
Base.getindex(g::_GetSingleton, a...) = _Get([a])

Base.getproperty(g::_MthdSingleton, a::Symbol) = _Mthd([a])
Base.getindex(g::_MthdSingleton, a...) = _Mthd([a])

Base.getproperty(g::_SetSingleton, a::Symbol) = _Set([a])
Base.getindex(g::_SetSingleton, a...) = _Set([a])

Base.getindex(g::_GetsSingleton, a...) = _Gets(a)
Base.getindex(g::_SetsSingleton, a...) = _Sets(a)

Base.getproperty(g::_AbstGet, a::Symbol) =
    (
        itms = Base.getfield(g, :__itms);
        a == :__itms ? itms : (append!(itms, [a]); g)
    )
Base.getindex(g::_AbstGet, a...) = (append!(g.__itms, a); g)

_get_prp_idx(o, a::Symbol) = Base.getproperty(o, a)
_get_prp_idx(o, a) = Base.getindex(o, a...)
_set_prp_idx(o, a::Symbol, x) = Base.setproperty!(o, a, x)
_set_prp_idx(o, a, x) = Base.setindex!(o, x, a...)

(g::_Grb)(obj::Any) = reduce(_get_prp_idx, g.__itms; init=obj)
(g::_Get)(obj::Any) = reduce(_get_prp_idx, g.__itms; init=obj)
(g::_Mthd)(a...; ka...) =
    obj -> reduce(_get_prp_idx, g.__itms; init=obj)(a...;ka...)
(g::_Set)(x) =
    obj -> (y = reduce(_get_prp_idx, g.__itms[1:end-1]; init=obj);
            _set_prp_idx(y, g.__itms[end], x);
            obj)
(g::_Gets)(obj::Any) = map(a -> _get_prp_idx(obj, a), g.__itms)
(g::_Sets)(x...) = obj -> map(((a,y),) -> _set_prp_idx(obj, a, y), zip(g.__itms, x))

###########
# cry, wc, wd
###########

cry(f, n::Integer=1) =
    begin
        if n < 0
            (x...; xkwa...) -> ((y...; ykwa...) -> f(x[1:end+n+1]...,
                                                     y...,
                                                     x[end+n+2:end]...;
                                                     merge(xkwa, ykwa)...))
        elseif n > 0
            (x...; xkwa...) -> ((y...; ykwa...) ->f(x[1:n-1]...,
                                                    y...,
                                                    x[n:end]...;
                                                    merge(xkwa, ykwa)...))
        else # n == 0
            cry(f,1)
        end
    end

Base.getproperty(::typeof(cry), p::Symbol) = cry(eval(p))

wc(f) = cry(f)
Base.getproperty(::typeof(wc), p::Symbol) = wc(eval(p))

wd(f) = cry(f, -1)
Base.getproperty(::typeof(wd), p::Symbol) = wd(eval(p))

macro cry(f)
    esc( :($f(a...;ka...) = x -> $f(x, a...; ka...)))
end

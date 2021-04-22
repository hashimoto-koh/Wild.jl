###############################
# functionalize
###############################
struct _functionalize{F} <: Function; f::F; end
@inline (f::_functionalize)(a...; ka...) = f.f(a...; ka...)

@inline functionalize(f) = _functionalize(f)
@inline functionalize(f::Function) = f
@inline functionalize(s::Symbol) = o -> getproperty(o, s)
@inline functionalize(s::Union{Tuple, AbstractArray, Base.Generator}) =
    (a...; ka...) -> map(f->functionalize(f)(a...; ka...), s)
@inline functionalize(s::NamedTuple) =
    (a...; ka...) -> map(f->functionalize(f)(a...; ka...), values(s))

###############################
# arg
###############################

struct _Args{A,KA} <: Function
    a::A
    ka::KA
end
@inline (a::_Args)(f) = functionalize(f)(a.a...; a.ka...)

@inline arg(a...; ka...) = _Args(a, ka)

###############################
# grb, mth, asn, grbs, asns
###############################

#=
x |> grb.a = x.a
x |> grb[10] = x[10]
x |> grb.a[10] = x.a[10]
x |> grb(:a) = x.a

x |> asn.a(3) ===> (x.a = 3; x)
x |> asn.a[10](3) ===> (x.a[10] = 3; x)
x |> asn[10](3) ===> (x[10] = 3; x)
x |> asn(:a)(3) ===> (x.a = 3; x)

x |> mth.a(10) == x.a(10)
x |> mth[10](3) == x[10](3)
x |> mth(:a)(3) == x.a(3)

x |> grbs[5, 3] ===> [x[5], x[3]]
x |> grbs(:a, :b) ===> [x.a, x.b]

x |> asns[5, 3](10, 20) ===> (x[5] = 10; x[3] = 20; x)
x |> asns(:a, :b)(10, 20) ===> (x.a = 10; x.b = 20; x)
=#

abstract type _AbstGet <: Function end

Base.getproperty(g::_AbstGet, a::Symbol) =
    begin
        itms = Base.getfield(g, :__itms);
        a == :__itms ? itms : (append!(itms, [a]); g)
    end
Base.getindex(g::_AbstGet, a...) = (append!(g.__itms, a); g)

_grb_prp_idx(o, a::Symbol) = Base.getproperty(o, a)
_grb_prp_idx(o, a) = Base.getindex(o, a...)
_asn_prp_idx(o, a::Symbol, x) = Base.setproperty!(o, a, x)
_asn_prp_idx(o, a, x) = Base.setindex!(o, x, a...)

########### grb
struct _GrbSingleton end
const grb = _GrbSingleton()
(s::_GrbSingleton)(atr::Symbol) = Base.getproperty(s, atr)
Base.getproperty(g::_GrbSingleton, a::Symbol) = _Grb([a])
Base.getindex(g::_GrbSingleton, a...) = _Grb([a])
mutable struct _Grb <: _AbstGet __itms::Vector{Any} end
(g::_Grb)(obj::Any) = reduce(_grb_prp_idx, g.__itms; init=obj)

########### asn
struct _AsnSingleton end
const asn = _AsnSingleton()
(::_AsnSingleton)(atr::Symbol) = x -> (o -> Base.setproperty!(o, atr, x))
Base.getproperty(g::_AsnSingleton, a::Symbol) = _Asn([a])
Base.getindex(g::_AsnSingleton, a...) = _Asn([a])
mutable struct _Asn <: _AbstGet __itms::Vector{Any} end
(g::_Asn)(x) =
    obj -> (y = reduce(_grb_prp_idx, g.__itms[1:end-1]; init=obj);
            _asn_prp_idx(y, g.__itms[end], x);
            obj)

########### grbs
struct _GrbsSingleton end
const grbs = _GrbsSingleton()
(::_GrbsSingleton)(a...) = o -> map(x -> Base.getproperty(o, x), a)
Base.getindex(g::_GrbsSingleton, a...) = o -> map(x -> Base.getindex(o, x), a)

########### asns
struct _AsnsSingleton end
const asns = _AsnsSingleton()
(::_AsnsSingleton)(a...) =
    (b...) -> (o -> (map((atr, x) -> Base.setproperty!(o, atr, x), zip(a, b)); o))
Base.getindex(g::_AsnsSingleton, a...) =
    (b...) -> (o -> (map((atr, x) -> Base.setindex!(o, atr, x), zip(a, b)); o))

########### mth
struct _MthSingleton end
const mth = _MthSingleton()
(s::_MthSingleton)(atr::Symbol) =
    (a...; ka...) -> (o -> Base.getproperty(o, atr)(a...; ka...))
Base.getproperty(g::_MthSingleton, a::Symbol) = _Mth([a])
Base.getindex(g::_MthSingleton, a...) = _Mth([a])
mutable struct _Mth <: _AbstGet __itms::Vector{Any} end
(g::_Mth)(a...; ka...) =
    obj -> reduce(_grb_prp_idx, g.__itms; init=obj)(a...;ka...)

###########
# cry, wc, wd
###########

cry(f, n::Integer=1) =
    (x...; xkwa...) ->
        ((y...; ykwa...) ->
             f(x[1:(n==0 ? 0 : (n>0 ? n-1 : end+n+1))]...,
               y...,
               x[(n==0 ? 1 : (n>0 ? n : end+n+2)):end]...;
               xkwa..., ykwa...))
               # merge(n>=0 ? xkwa : ykwa, n>=0 ? ykwa : xkwa)...))
    #=
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
    =#

Base.getproperty(::typeof(cry), p::Symbol) = cry(eval(p))

wc(f) = cry(f)
Base.getproperty(::typeof(wc), p::Symbol) = wc(eval(p))

wd(f) = cry(f, -1)
Base.getproperty(::typeof(wd), p::Symbol) = wd(eval(p))

macro cry(f)
    esc( :($f(a...;ka...) = x -> $f(x, a...; ka...)))
end

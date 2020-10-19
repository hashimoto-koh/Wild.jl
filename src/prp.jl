import DataStructures: DefaultDict

###############################
# @prp
###############################

struct __IsaPrp end
struct __IsnotaPrp end
@inline __isprp(x) = __IsnotaPrp()
@inline __asprp(f) = __asprp(__isprp(f), f)
@inline __asprp(::__IsaPrp, f) = o -> f(o)
@inline __asprp(::__IsnotaPrp, f) = o -> ((a...;ka...) -> f(o, a...; ka...))

export @prp

macro prp(ex)
    # f
    if isa(ex, Symbol)
        f = ex
        esc(:(@inline Wild.__isprp(::typeof($f)) = Wild.__IsaPrp()))
    # function f(x) 2x end
    elseif ex.head == :function
        f = ex.args[1].args[1]
        ff = :(@inline Wild.__isprp(::typeof($f)) = Wild.__IsaPrp())
        esc(Expr(:toplevel, ex, ff))
    elseif ex.head == :(=)
        # f(x) = 2x
        if isa(ex.args[1], Expr) && ex.args[1].head == :call
            f = ex.args[1].args[1]
            ff = :(@inline Wild.__isprp(::typeof($f)) = Wild.__IsaPrp())
            esc(Expr(:toplevel, ex, ff))
        # f = x -> 2x
        else
            f = ex.args[1]
            ff = :(@inline Wild.__isprp(::typeof($f)) = Wild.__IsaPrp())
            esc(Expr(:toplevel, ex, ff))
        end
    else
        f = ex
        esc(:(@inline Wild.__isprp(::typeof($f)) = Wild.__IsaPrp()))
    end
end

@prp Base.methods
@prp Base.inv
@prp Base.real
@prp Base.imag
@prp Base.reim
@prp Base.abs
@prp Base.abs2
@prp Base.conj
@prp Base.angle
@prp Base.cis
@prp Base.extrema
@prp Base.minimum
@prp Base.maximum
@prp Base.one
@prp Base.zero
@prp Base.keys
@prp Base.values
@prp Base.typeof
@prp Base.println
@prp Base.length
@prp Base.adjoint
@prp Base.transpose

###############################
# prpdict
###############################
#=
Base.getproperty(o::Any, atr::Symbol) =
    (hasfield(typeof(o), atr)
     ? Base.getfield(o, atr)
     : __asprp(Base.eval(Base.Main, atr))(o))
=#
PrpDct = DefaultDict{Symbol, Function}
# PrpDct = Dict{Symbol, Function}

struct __getprp_dict <: Function
    __dct::Dict{Type, PrpDct}
end

Base.getindex(d::__getprp_dict, T::Type) = d.__dct[T]
Base.getindex(d::__getprp_dict, T::Type, atr::Symbol) = d.__dct[T][atr]
Base.setindex!(d::__getprp_dict, x::PrpDct, T::Type) =
    Base.setindex!(d.__dct, x, T)
Base.setindex!(d::__getprp_dict, f::Function, T::Type, atr::Symbol) =
    Base.setindex!(d.__dct[T], f, atr)

getprp_dict = __getprp_dict(Dict{Type, PrpDct}())

for T in [Any,
          Number,
          AbstractArray,
          AbstractString,
          Function,
          Base.Generator,
          Iterators.ProductIterator,
          ]
#    getprp_dict.__dct[T] = PrpDct()
    getprp_dict.__dct[T] =
        PrpDct(atr -> __asprp(Base.eval(Base.Main, atr)), passkey=true)

    Base.getproperty(o::T, atr::Symbol) =
        hasfield(typeof(o), atr) ? Base.getfield(o, atr) : getprp_dict[T][atr](o)
    Base.hasproperty(o::T, atr::Symbol) =
        tuple(fieldnames(typeof(o))..., keys(getprp_dict[T]))
    Base.propertynames(o::T, private=false) =
        hasfield(typeof(o), atr) || haskey(getprp_dict[T])
end

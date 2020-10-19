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

# __PrpDct = DefaultDict{Symbol, Function}
__PrpDct = Dict{Symbol, Function}
struct __getprp_dct <: Function _dct::Dict{Type, __PrpDct} end
Base.getindex(d::__getprp_dct, T::Type) = d._dct[T]
Base.setindex!(d::__getprp_dct, x::__PrpDct, T::Type) = Base.setindex!(d._dct, x, T)

getprp_dct = __getprp_dct(Dict{Type, __PrpDct}())

for T in [Any,
          Number,
          AbstractArray,
          AbstractRange,
          AbstractString,
          Function,
          Base.Generator,
          Iterators.ProductIterator,
          ]
#    getprp_dct[T] = __PrpDct(a -> __asprp(Base.eval(Base.Main, a)), passkey=true)
    getprp_dct[T] = __PrpDct()
    Base.getproperty(o::T, atr::Symbol) = (hasfield(typeof(o), atr)
                                           ? Base.getfield(o, atr)
                                           : haskey(getprp_dct[T], atr)
                                           ? getprp_dct[T][atr](o)
                                           : __asprp(Base.eval(Base.Main, atr)))
    Base.hasproperty(o::T, atr::Symbol) =
        tuple(fieldnames(typeof(o))..., keys(getprp_dct[T]))
    Base.propertynames(o::T, private=false) =
        hasfield(typeof(o), atr) || haskey(getprp_dct[T])
end

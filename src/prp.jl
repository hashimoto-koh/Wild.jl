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

const base_getprp_dict = Dict{Type, Dict{Symbol, Function}}()

base_getprp_dict[Any] = Dict{Symbol, Function}()
base_getprp_dict[AbstractArray] = Dict{Symbol, Function}()
base_getprp_dict[AbstractString] = Dict{Symbol, Function}()

Base.getproperty(o::Any, atr::Symbol) =
begin
    hasfield(typeof(o), atr) && (return Base.getfield(o, atr))
    haskey(base_getprp_dict[Any], atr) && (return base_getprp_dict[Any][atr](o))
    __asprp(Base.eval(Base.Main, atr))(o)
end

Base.getproperty(o::AbstractArray, atr::Symbol) =
begin
    hasfield(typeof(o), atr) && (return Base.getfield(o, atr))
    haskey(base_getprp_dict[AbstractArray], atr) &&
        (return base_getprp_dict[AbstractArray][atr](o))
    __asprp(Base.eval(Base.Main, atr))(o)
end

Base.getproperty(o::AbstractString, atr::Symbol) =
begin
    hasfield(typeof(o), atr) && (return Base.getfield(o, atr))
    haskey(base_getprp_dict[AbstractString], atr) &&
        (return base_getprp_dict[AbstractString][atr](o))
    __asprp(Base.eval(Base.Main, atr))(o)
end

module Wild

include("functionalize.jl")
export arg, grb, asn, mth, grbs, asns, cry, wc, wd, @cry

# include("core.jl")
# export AbstTagFunc, AbstPrpFunc, AbstMthFunc
# export @prp, @mth
# export @prpfnc, @mthfnc

include("ns_dict0.jl")
include("ns.jl")
include("ns_tags.jl")
export AbstNS, NS
export NSX, genNSX, nsx, AbstNSitem
export NSTagFunc
export NSDfn, NSReq, NSMth, NSPrp, NSFnc

#=
include("nscls.jl")
export AbstNSCls, NSCls
=#

include("nscode_dict0.jl")
include("nscode.jl")
export AbstNSCode, NSCode

include("operators.jl")
#=
struct __IsaPrp end
struct __IsnotaPrp end
@inline __isprp(x) = __IsnotaPrp()
@inline __asprp(f) = __asprp(__isprp(f), f)
@inline __asprp(::__IsaPrp, f) = o -> f(o)
@inline __asprp(::__IsnotaPrp, f) = o -> ((a...;ka...) -> f(o, a...; ka...))

export @prp
#=
macro prp(ex)
    # function f(x) 2x end
    if ex.head == :function
        eval(esc(ex))
        f = ex.args[1].args[1]
    elseif ex.head == :=
        eval(esc(ex))
        # f(x) = 2x
        if isa(ex.args[1], Expr) && ex.args[1].head == :call
            f = ex.args[1].args[1]
        # f = x -> 2x
        else
            f = ex.args[1]
        end
    # f
    else
        f = ex
    end
    :(@inline Wild.__isprp(::typeof(esc(f))) = Wild.__IsaPrp())
end
=#

macro prp(f)
    :(@inline Wild.__isprp(::typeof(esc(f))) = Wild.__IsaPrp())
end

Base.getproperty(o::Any, atr::Symbol) =
begin
    hasfield(typeof(o), atr) && (return Base.getfield(o, atr))
    __asprp(Base.eval(Base.Main, atr))(o)
end
#=
Base.getproperty(o::Any, atr::Symbol) =
    (hasfield(typeof(o), atr)
     ? Base.getfield(o, atr)
     : (f = Base.eval(Base.Main, atr);
        (isa(f, Union{AbstTagFunc, NSTagFunc}) ? f : NSTagFunc{:mth}(f))(o)))
=#
=#

end

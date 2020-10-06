module Wild

include("functionalize.jl")
export arg, grb, asn, mth, grbs, asns, cry, wc, wd, @cry

include("core.jl")
export AbstTagFunc, AbstPrpFunc, AbstMthFunc
export @prp, @mth
# export @dfn, @req, @prp, @mth, @fnc, @sprp
export @prpfnc, @mthfnc

include("ns_dict0.jl")
include("ns.jl")
include("ns_tags.jl")
export AbstNS, NS
export NSX, genNSX, nsx, AbstNSitem
# export AbstNSTagFunc
# export NSDfn, NSReq, NSMth, NSPrp, NSFnc

#=
include("nscls.jl")
export AbstNSCls, NSCls
=#

include("nscode_dict0.jl")
include("nscode.jl")
export AbstNSCode, NSCode

include("operators.jl")

Base.getproperty(o::Any, atr::Symbol) =
    (hasfield(typeof(o), atr)
     ? Base.getfield(o, atr)
     : (f = Base.eval(Base.Main, atr);
        (isa(f, NSTagFunc) ? f : NSTagFunc{:mth}(f))(o)))

end

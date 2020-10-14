module Wild

include("functionalize.jl")
export arg, grb, asn, mth, grbs, asns, cry, wc, wd, @cry

include("ns_dict0.jl")
include("ns.jl")
include("ns_tags.jl")
export AbstNS, NS
export NSX, genNSX, nsx, AbstNSitem
export NSTagFunc
export NSDfn, NSReq, NSMth, NSPrp, NSFnc


include("nscls_dict0.jl")
include("nscls.jl")
export AbstNSCls, NSCls


include("nscode_dict0.jl")
include("nscode.jl")
export AbstNSCode, NSCode

include("operators.jl")

include("prp.jl")

Base.getproperty(o::Any, atr::Symbol) =
begin
    hasfield(typeof(o), atr) && (return Base.getfield(o, atr))
    __asprp(Base.eval(Base.Main, atr))(o)
end

end

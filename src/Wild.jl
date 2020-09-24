module Wild

include("core.jl")
export AbstTagFunc
export @dfn, @req, @prp, @mth, @sprp
export AbstFunc, AbstPrpFunc, AbstMthFunc
export @prpfnc, @mthfnc
export AbstClassFunc
export Dfn, Req, Prp, Mth, SetPrp
export dfn, req, prp, mth, sprp

include("functionalize.jl")
export arg, cry, wc, wd, @cry

include("ns_dict0.jl")
include("ns.jl")
include("ns_tags.jl")
export AbstNS, NS
export NSGen, nsgen, ns, AbstNSitem
export AbstNSX, NSX, NSXinit, prm, nsx

include("nscls.jl")
export AbstNSCls, NSCls

include("nscode.jl")
export AbstNSCode, NSCode

include("operators.jl")

Base.getproperty(o::Any, atr::Symbol) =
    (hasfield(typeof(o), atr)
     ? Base.getfield(o, atr)
     : (f = Base.eval(Base.Main, atr); (isa(f, AbstTagFunc) ? f : Mth(f))(o)))

end

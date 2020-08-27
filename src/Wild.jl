module Wild

include("core.jl")
export AbstTagFunc
export @dfn, @prp, @mth, @sprp
export AbstFunc, AbstPrpFunc, AbstMthFunc
export @prpfnc, @mthfnc
export AbstClassFunc
export Dfn, Prp, Mth, SetPrp
export dfn, prp, mth, sprp

Base.getproperty(o::Any, atr::Symbol) =
    (hasfield(typeof(o), atr)
     ? Base.getfield(o, atr)
     : (f = Base.eval(Base.Main, atr); (isa(f, AbstTagFunc) ? f : Mth(f))(o)))

end

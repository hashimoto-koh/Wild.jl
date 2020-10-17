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

end

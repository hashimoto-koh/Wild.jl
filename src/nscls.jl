import Dates
import SHA

################
# NSClsInstance{X}
################

struct NSClsInstance{X} <: AbstNS
    __dict::OrderedDict{Symbol, AbstNSitem}
    __fix_lck::MVector{2, Bool}
    cls::NS

    NSClsInstance{X}(cls) where X =
        new{X}(#= __dict    =# OrderedDict{Symbol, AbstNSitem}(),
               #= __fix_lck =# MVector{2, Bool}(false, false),
               #= cls       =# cls)
end

Base.getproperty(nsi::NSClsInstance, atr::Symbol) =
    begin
        Base.hasfield(typeof(nsi), atr) && (return Base.getfield(nsi, atr))

        haskey(_NSdict0, atr) && (return _NSdict0[atr](nsi))

        d = nsi.__dict

        if haskey(d, atr)
            x = d[atr].obj;
            isa(x, Union{NSTagFunc{:prp}, NSTagFunc{:mth}}) && (return x(nsi))
            isa(x, NSTagFunc{:fnc}) && (return x.fnc)
            isa(x, NSTagFunc{:req}) &&
                (y = x(ns);
                 d[atr] = (isa(d[atr], NScst_item) ? NScst_item : NSnoncst_item)(y);
                 return y)
            return x
        else
            haskey(nsi.cls, atr) && (return Base.getproperty(nsi.cls, atr))
            error("""This NS does not have a property named "$(atr)".""")
        end
    end

################
# NSCls
################

struct NSCls <: AbstNSCls
    __args::Tuple{Vararg{Symbol}}
    __kargs
    __cls::NS
    __code::__NSX_CodeMode
    __type
    __instances
    __link_instances::Bool
    __init::Vector{Union{Nothing, NSTagFunc{:mth}}}
    __post::Vector{Union{Nothing, NSTagFunc{:mth}}}

    NSCls(args...; __link_instances=false, kargs...) =
        begin
            nsc = new(#= __args           =# args,
                      #= __kargs          =# kargs,
                      #= __cls            =# NS(),
                      #= __code           =# __NSX_CodeMode(),
                      #= __type           =# NSClsInstance{gensym()},
                      #= __instances      =# [],
                      #= __link_instances =# __link_instances,
                      #= __init           =# [nothing],
                      #= __post           =# [nothing])
            push!(nsc.__code.__instances, nsc.__instances)
            nsc
        end
end

(nsc::NSCls)(args...; kargs...) =
    begin
        o = nsc.__type(nsc.__cls)

        na = length(nsc.__args)
        nka = length(nsc.__kargs)

        length(args) < na &&
            Base.error("number of args should be equal to or larger than $na")

        for (atr, val) ∈ zip(nsc.__args, args[1:na])
            Base.setproperty!(o, atr, val)
        end

        for (atr, val) ∈ nsc.__kargs
            Base.setproperty!(o, atr, atr ∈ keys(kargs) ? kargs[atr] : val)
        end

        isnothing(nsc.__init[1]) ||
            nsc.__init[1](o)(args[na+1:end]...;
                             Dict((k,v)
                                  for (k,v) ∈ kargs if k ∉ keys(nsc.__kargs))...)

        for (atr, val) ∈ pairs(nsc.__code.__dict)
            x = isa(val, NScst_item) ? Base.getproperty!(o, :cst) : o
            y = (isa(val.obj, NSTagFunc)
                 ? Base.getproperty(x, typeof(val.obj).parameters[1])
                 : x)
            z = isa(val.obj, NSTagFunc) ? val.obj.fnc : val.obj
            Base.setproperty!(y, atr, z)
        end
        isnothing(nsc.__post[1]) || nsc.__post[1](o)();

        nsc.__link_instances &&
            append!(nsc.__instances, [(a=args, k=values(kargs), o=o)])
        o
    end

Base.setproperty!(nsc::AbstNSCls, atr::Symbol, x) =
    begin
        hasfield(typeof(nsc), atr) &&
            (Base.setfield!(nsc, atr, x); return)

        atr == :init && (nsc.__init[1] = NSTagFunc{:mth}(x); return)
        atr == :post && (nsc.__post[1] = NSTagFunc{:mth}(x); return)

        haskey(_NSClsdict0, atr) &&
            Base.error("'" * string(atr) * "' can't be used for property")

        nsc.__cls.haskey(atr) && (return Base.setproperty!(nsc.__cls, atr, x))

        Base.setproperty!(nsc.__code, atr, x)
    end

Base.propertynames(nsc::AbstNSCls, private=false) =
    tuple(Base.propertynames(nsc.__cls, private)...,
          Base.keys(_NSClsdict0)...,
          Base.fieldnames(typeof(nsc))...)

Base.hasproperty(nsc::AbstNSCls, atr::Symbol) =
    Base.hasfield(typeof(nsc), atr) ||
    haskey(_NSClsdict0, atr) ||
    Base.hasproperty(nsc.__cls, atr)

Base.getproperty(nsc::AbstNSCls, atr::Symbol) =
    begin
        Base.hasfield(typeof(nsc), atr) && (return Base.getfield(nsc, atr))
        haskey(_NSClsdict0, atr) && (return _NSClsdict0[atr](nsc))
        Base.getproperty(nsc.__cls, atr)
    end


#=
#=
### Example

c = NSCls(:Ex, true)
c.n = 0

c.fnc.init = (cls, g, i, x, y, z) ->
begin
    g.i = i
    (g.a, g.b, g.c) = x, y, z
    g.prp.d = g -> g.a + g.b + g.c
    g.req.e = g -> 10 * g.d
    cls.n += 1
end

c.fnc.init = (ns, g, i, x, y) -> c.init(g, i,, x, y, 10x+y)

g1 = c(1, 3, 4, 5)
g2 = c(2, 30, 4)

c.toinstances = g ->
begin
    g.x= 0:0.01:3π
    g.fnc.f = (g,f) -> pl.x(g.x).plot(f.(g.x * g.a))
end

c.toinstances = g -> println(g.e)

c.toinstances = g -> g.f(cos);

=#

abstract type AbstNSCls <: AbstNS end

struct NSCls <: AbstNSCls
    __dict::OrderedDict{Symbol, AbstNSitem}
    __fix_lck::MVector{2, Bool}
    __type::Type
    __instances::Union{Nothing, Vector{AbstNS}}
    NSCls(name::Union{Nothing, AbstractString, Symbol}=nothing,
          keep_instances::Bool=false) =
        begin
            name = (isnothing(name)
                    ? Symbol("NS_"*string(bytes2hex(SHA.sha256(string(time_ns())))))
                    : Symbol(name))
            Type = NSGen{name}
            x = new(#= __dict    =#
                    OrderedDict{Symbol, AbstNSitem}(),
                    #= __fix_lck =#
                    MVector{2, Bool}(false, false),
                    #= __type    =#
                    Type,
                    #= __instances =#
                    keep_instances ? Vector{AbstNS}() : nothing)
            x.cst.sprp.toinstances = (cls, f) -> isnothing(cls.__instances) ||
                                                 [f(g) for g ∈ cls.__instances]
            x
        end
end

(cls::NSCls)(a...; ka...) =
begin
    g = cls.__type()
    isnothing(cls.__instances) || push!(cls.__instances, g)
    haskey(cls, :init) && cls.init(g, a...; ka...)
    g
end
=#

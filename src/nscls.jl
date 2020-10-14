import Dates
import SHA

################
# NSCls
################

struct NSCls <: AbstNSCls
    __args::Tuple{Vararg{Symbol}}
    __kargs
    __cls::NS
    __code::NSX{__NSFlgCodeMode}
    __type
    __instances
    __link_instances::Bool
    __init::Array{Union{Nothing, NSTagFunc{:mth}}}
    _instances::Nothing
    _clr_instances::Nothing

    NSCls(args...; __link_instances=false, kargs...) =
        new(#= __args           =# args,
            #= __kargs          =# kargs,
            #= __cls            =# NS(),
            #= __code           =# NSX{__NSFlgCodeMode}(),
            #= __type           =# genNSX(),
            #= __instances      =# [],
            #= __link_instances =# __link_instances,
            #= __init           =# [nothing],
            #= _instances       =# nothing,
            #= _clr_instances   =# nothing)
end
#=
function push_to_instance(o, atr, val)
    x = isa(val, NSClscst_item) ? Base.getproperty(o, :cst) : o

    y = (isa(val, AbstNSClsitem) && isa(val.obj, NSTagFunc)
         ? Base.getproperty(x, typeof(val.obj).parameters[1])
         : x)

    if !isa(val, AbstNSClsitem)
        if atr == :exe
            val(y)
        else
            Base.setproperty!(y, atr, val)
        end
    elseif isa(val.obj, NSTagFunc)
        Base.setproperty!(y, atr, val.obj.fnc)
    else
        Base.setproperty!(y, atr, val.obj)
    end
end
=#
(nsc::NSCls)(args...; kargs...) =
    begin
        o = nsc.__type()

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
            if isa(val, NScst_item)
                x = Base.getproperty!(o, :cst)
                if isa(val.obj, NSTagFunc)
                    tag = typeof(val.obj).parameters[1]
                    Base.setproperty!(Base.getproperty(x, tag), atr, val.obj.fnc)
                else
                    Base.setproperty!(x, atr, val.obj)
                end
            else
                if isa(val.obj, NSTagFunc)
                    tag = typeof(val.obj).parameters[1]
                    Base.setproperty!(Base.getproperty(o, tag), atr, val.obj.fnc)
                else
                    Base.setproperty!(o, atr, val.obj)
                end
            end
        end

        nsc.__link_instances &&
            append!(nsc.__instances, [(a=args, k=values(kargs), o=o)])
        o
    end

Base.setproperty!(nsc::AbstNSCls, atr::Symbol, x) =
    begin
        hasfield(typeof(nsc), atr) &&
            (Base.setfield!(nsc, atr, x); return)

        atr == :init && (nsc.__init[1] = NSTagFunc{:mth}(x); return)

        haskey(_NSClsdict0, atr) &&
            Base.error("'" * string(atr) * "' can't be used for property")

        nsc.__link_instances &&
            [Base.setproperty!(i, atr, x) for (a, k, i) ∈ nsc.__instances]

        Base.setproperty!(nsc.__code, atr, x)
    end

Base.getproperty(nsc::AbstNSCls, atr::Symbol) =
    begin
        Base.hasfield(typeof(nsc), atr) && (return Base.getfield(nsc, atr))
        haskey(_NSClsdict0, atr) && (return _NSClsdict0[atr](nsc))
        Base.getproperty(nsc.__cls, atr)
    end

################
# NSClsitem
################

abstract type AbstNSClsitem end

struct NSClscst_item{T} <: AbstNSClsitem
    obj::T
end

mutable struct NSClsnoncst_item{T} <: AbstNSClsitem
    obj::T
end

################
# NSClsTag
################

struct NSClsTag{T, C} ___NSC_nsc::AbstNSCls end

Base.setproperty!(tag::NSClsTag, atr::Symbol, f) =
        (Base.hasfield(typeof(tag), atr)
         ? Base.setproperty!(tag, atr, f)
         : Base.setproperty!(tag.___NSC_nsc, atr, _MakeItem(tag,f)))

################
# NSClscst
################

struct NSClscst{T <: AbstNSCls} ___NSC_nsc::T end

Base.getproperty(cst::NSClscst, atr::Symbol) =
    begin
        hasfield(typeof(cst), atr) && (return Base.getfield(cst, atr))
        NSClsTag{atr, true}(cst.___NSC_nsc)
    end

Base.setproperty!(cst::NSClscst, atr::Symbol, o) =
    Base.setproperty!(cst.___NSC_nsc, atr, NScst_item(o))

_MakeItem(x::NSClscst, o) = NScst_item(o)

################
# NSClsTagFunc
################

struct NSClsTagFunc{T, C} nsc::AbstNSCls end
_MakeItem(x::NSClsTag{T,false}, f) where T = NSnoncst_item(NSTagFunc{T}(f))
_MakeItem(x::NSClsTag{T, true}, f) where T = NScst_item(NSTagFunc{T}(f))


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

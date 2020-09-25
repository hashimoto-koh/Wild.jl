import DataStructures: OrderedDict
import StaticArrays: MVector
import Serialization
import SHA

################
# NSitem
################

abstract type AbstNSitem end

struct NScst_item{T} <: AbstNSitem
    obj::T
end

mutable struct NSnoncst_item <: AbstNSitem
    obj
end

################
# NS
################

struct NS <: AbstNS
    __dict::OrderedDict{Symbol, AbstNSitem}
    __fix_lck::MVector{2, Bool}
    __mdl::Module

    NS(mdl=@__MODULE__) =
        new(#= __dict    =# OrderedDict{Symbol, AbstNSitem}(),
            #= __fix_lck =# MVector{2, Bool}(false, false),
            #= __mdl     =# mdl)
end

macro NS()
    return esc(:(NS(@__MODULE__)))
end

################
# NSGen{X}
################

struct NSGen{X} <: AbstNS
    __dict::OrderedDict{Symbol, AbstNSitem}
    __fix_lck::MVector{2, Bool}
    __mdl::Module

    NSGen{X}(mdl=@__MODULE__) where X =
        new{X}(#= __dict    =# OrderedDict{Symbol, AbstNSitem}(),
               #= __fix_lck =# MVector{2, Bool}(false, false),
               #= __mdl     =# mdl)
end

macro NSGen(X)
    return esc(:(NSGen{$(X)}(@__MODULE__)))
end

################
# NS
################

Base.setproperty!(ns::AbstNS, atr::Symbol, x) =
    begin
        hasfield(typeof(ns), atr) && (return Base.setfield!(ns, atr, x))

        atr == :exe && (return x(ns))

        atr ∈ Base.keys(_NSdict0) &&
            Base.error("'" * string(atr) * "' can't be used for property")

        if haskey(ns.__dict, atr)
            ns._fixed && Base.error("this NS is fixed!")

            if isa(ns.__dict[atr].obj, SetPrp)
                ns.__dict[atr].obj.fnc(ns, x)
            elseif isa(x, AbstNSitem) && isa(x.obj, Fnc)
                if isa(ns.__dict[atr].obj, Fnc)
                    ns.__dict[atr].obj.append!(x.obj.fnclist)
                else
                    ns.__dict[atr].obj = x.obj
                end
            else
                ns.__dict[atr].obj = isa(x, AbstNSitem) ? x.obj : x
            end
        else
            ns._lcked && Base.error("this NS is locked!")
            ns.__dict[atr] = isa(x, AbstNSitem) ? x : NSnoncst_item(x)
        end
        ns
    end

Base.haskey(o::AbstNS, key::Symbol) = key ∈ o._keys

Base.propertynames(ns::AbstNS, private=false) =
    tuple(Base.keys(ns.__dict)...,
          Base.keys(_NSdict0)...,
          Base.fieldnames(typeof(ns))...)

Base.hasproperty(ns::AbstNS, atr::Symbol) =
    Base.hasfield(typeof(ns), atr) ||
    haskey(_NSdict0, atr) ||
    haskey(ns.__dict, atr)

Base.getproperty(ns::AbstNS, atr::Symbol) =
    begin
        Base.hasfield(typeof(ns), atr) && (return Base.getfield(ns, atr))

        haskey(_NSdict0, atr) && (return _NSdict0[atr](ns))

        d = ns.__dict

        haskey(d, atr) ||
            error("""This NS does not have a property named "$(atr)".""")
            # x -> (Base.setproperty!(ns, atr, x); ns)

        x = d[atr].obj;
        isa(x, Union{Prp, Mth, Fnc}) && (return x(ns))
        isa(x, Req) && (y = x(ns); d[atr] = typeof(d[atr])(y); return y)
        return x
    end

################
# >>, >>>
################

Base.:>>( g::AbstNS, h::AbstNS) = h.import(g)
Base.:>>>(g::AbstNS, h::AbstNS) = h.deepimport(g)

################
# nsgen, ns
################

nsgen() = NSGen{Symbol("NS_" * string(bytes2hex(SHA.sha256(string(time_ns())))))}
nsgen(name::Union{Symbol, AbstractString}) = NSGen{name}

ns(mdl=@__MODULE__) = nsgen()(mdl)
ns(name::Union{Symbol, AbstractString}, mdl=@__MODULE__) = nsgen(name)(mdl)

macro ns(name)
    return esc(:(ns($(name), @__MODULE__)))
end

################
# AbstNSX, NSX, NSXinit, prm, nsx
################
#=
[1] default constructor が必要ないなら
G = NSX{:G}
NSX{:G}(a::Integer) = (g = G(); g.a = lapd(a, 3, "0"); g)
NSX{:G}(a::Union{String, Symbol}) = (g = G(); g.a = Symbol(a); g)

[2] default constructor が必要なら
G = NSX{:G}
NSX{:G}() = (g = NSXinit{G}(); g.a = 10; g)
NSX{:G}(a) = (g = G(); g.a = g.a + a; g)
NSX{:G}(a,b) = (g = NSXinit{G}(); g.a = a+b; g)

[3] type parameter を指定する必要がなければ
G = nsx()
NSX{prm(G)}() = (g = NSXinit{G}(); g.a = 10; g)
NSX{prm(G)}(a) = (g = G(); g.a = g.a + a; g)
NSX{prm(G)}(a,b) = (g = NSXinit{G}(); g.a = a+b; g)
=#

struct NSXinit{X} end

abstract type AbstNSX <: AbstNS end

struct NSX{X} <: AbstNSX
    __dict::OrderedDict{Symbol, AbstNSitem}
    __fix_lck::MVector{2, Bool}
    __mdl::Module
    global NSXinit{X}(mdl=@__MODULE__) where X =
        new{X.parameters[1]}(OrderedDict{Symbol, AbstNSitem}(),
                             MVector{2, Bool}(false, false),
                             mdl)
end

NSX{X}(mdl=@__MODULE__) where X = NSXinit{NSX{X}}(mdl)

macro NSX(X)
    return esc(:(NSX{$(X)}(@__MODULE__)))
end

prm(X) = X.parameters[1]

nsx() = NSX{Symbol("NSX_" * string(bytes2hex(SHA.sha256(string(time_ns())))))}

################
# New NS macro
################
#=
macro makeNS(name)
    return esc(quote
               import DataStructures.OrderedDict
               import Wild.AbstNSitem
               struct $name <: AbstNS
                   __dict::OrderedDict{Symbol, AbstNSitem}
                   __fix_lck::Vector{Bool, 1}

               $name() = new(OrderedDict{Symbol, AbstNSitem}(),
                             [false, false])
               end
               end)
end
=#

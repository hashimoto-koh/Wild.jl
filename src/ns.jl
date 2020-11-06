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

mutable struct NSnoncst_item{T} <: AbstNSitem
    obj::T
end

Base.copy(x::Wild.AbstNSitem) = typeof(x)(x.obj)

################
# NSX{X}
################

struct NSX{X} <: AbstNS
    __dict::OrderedDict{Symbol, AbstNSitem}
    __fix_lck::MVector{2, Bool}

    NSX{X}() where X = new{X}(#= __dict    =# OrderedDict{Symbol, AbstNSitem}(),
                              #= __fix_lck =# MVector{2, Bool}(false, false))
end

const NS = NSX{nothing}

abstract type __NSFlgCodeMode end

################
# NS
################

Base.setproperty!(ns::AbstNS, atr::Symbol, x) =
    begin
        hasfield(typeof(ns), atr) && (return Base.setfield!(ns, atr, x))

        atr == :exe && (return x(ns))

        haskey(_NSdict0, atr) &&
            Base.error("""'$(atr)' can't be used for property""")

        d = ns.__dict

        if haskey(d, atr)
            ns._fixed && Base.error("this NS is fixed!")

            o = d[atr].obj
            isa(o, NSPrp) && (o.fnc(ns, x); return)

            isa(d[atr], NScst_item) && Base.error("""'$(atr)' is const.""")
        else
            ns._lcked && Base.error("this NS is locked!")
        end

        d[atr] = isa(x, AbstNSitem) ? copy(x) : NSnoncst_item(x)
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
            error("""this NS does not have a property named "$(atr)".""")

        x = d[atr].obj;
        isa(x, Union{NSPrp, NSMth}) && (return x(ns))
        isa(x, NSFnc) && (return x.fnc)
        isa(x, NSReq) &&
            (y = x(ns);
             d[atr] = (isa(d[atr], NScst_item) ? NScst_item : NSnoncst_item)(y);
             return y)
        return x
    end

################
# NSX{__NSFlgCodeMode}
################

struct __NSX_CodeMode <: AbstNS
    __dict::OrderedDict{Symbol, AbstNSitem}
    __fix_lck::MVector{2, Bool}
    __code::Vector{NamedTuple{(:atr, :obj),Tuple{Symbol,Any}}}
    __instances
    __NSX_CodeMode() =
        new(#= __dict      =# OrderedDict{Symbol, AbstNSitem}(),
            #= __fix_lck   =# MVector{2, Bool}(false, false),
            #= __code      =# Vector{NamedTuple{(:atr, :obj),Tuple{Symbol,Any}}}(),
            #= __instances =# [])
end

Base.setproperty!(ns::__NSX_CodeMode, atr::Symbol, x) =
    begin
        hasfield(typeof(ns), atr) && (return Base.setfield!(ns, atr, x))

        haskey(_NSdict0, atr) &&
            Base.error("""'$(atr)' can't be used for property""")

        y = atr == :exe ? x : isa(x, AbstNSitem) ? x : NSnoncst_item(x)

        push!(ns.__code, NamedTuple{(:atr, :obj), Tuple{Symbol, Any}}((atr, y)))

        for i in ns.__instances[1]
            Base.setproperty!(i.o, atr, x)
        end
    end

Base.getproperty(ns::__NSX_CodeMode, atr::Symbol) =
    begin
        Base.hasfield(typeof(ns), atr) && (return Base.getfield(ns, atr))

        haskey(_NSdict0, atr) && (return _NSdict0[atr](ns))

        d = ns.__dict

        haskey(d, atr) ||
            error("""This NS does not have a property named "$(atr)".""")

        d[atr].obj;
    end;

################
# >>, >>>
################

Base.:>>( g::AbstNS, h::AbstNS) = h.import(g)
Base.:>>>(g::AbstNS, h::AbstNS) = h.deepimport(g)

################
# genNSX, ns
################

# genNSX() = NSX{Symbol("NS_", string(bytes2hex(SHA.sha256(string(time_ns())))))}
genNSX() = NSX{gensym()}
genNSX(X) = NSX{X}

nsx() = genNSX()()
nsx(X) = genNSX(X)()

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

#=
struct NSXinit{X} end

abstract type AbstNSX <: AbstNS end

struct NSX{X} <: AbstNSX
    __dict::OrderedDict{Symbol, AbstNSitem}
    __fix_lck::MVector{2, Bool}
    global NSXinit{X}() where X =
        new{X.parameters[1]}(OrderedDict{Symbol, AbstNSitem}(),
                             MVector{2, Bool}(false, false))
end

NSX{X}() where X = NSXinit{NSX{X}}()

prm(X) = X.parameters[1]

nsx() = NSX{Symbol("NSX_", string(bytes2hex(SHA.sha256(string(time_ns())))))}
=#

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

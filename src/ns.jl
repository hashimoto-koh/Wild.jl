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
# __NSX_CodeMode
################

__NSX_CodeMode_CodeType = Vector{NamedTuple{(:atr, :obj),Tuple{Symbol,Any}}}
struct __NSX_CodeMode <: AbstNS
    __code::__NSX_CodeMode_CodeType
    __instances
    __parallel::NSnoncst_item{Bool}
    __NSX_CodeMode() =
        new(#= __code      =# __NSX_CodeMode_CodeType(),
            #= __instances =# [],
            #= __parallel  =# NSnoncst_item{Bool}(false))
end

__divNn(N::Integer, n::Integer) =
begin
    k1 = (let v = fill(N ÷ n, n); v[1:N%n] .+= 1; accumulate(+, v); end)
    k0 = (let v = similar(k1); v[1] = 1; @. v[2:end] = k1[1:end-1] + 1; v; end)
    [i0:i1 for (i0,i1) in zip(k0,k1)]
end

Base.setproperty!(ns::__NSX_CodeMode, atr::Symbol, x) =
    begin
        hasfield(typeof(ns), atr) && (return Base.setfield!(ns, atr, x))

        haskey(_NSdict0, atr) &&
            Base.error("""'$(atr)' can't be used for property""")

        y = atr == :exe ? x : isa(x, AbstNSitem) ? x : NSnoncst_item(x)

        push!(ns.__code, NamedTuple{(:atr, :obj), Tuple{Symbol, Any}}((atr, y)))

        inst = ns.__instances[1]
        if ns.__parallel.obj
            for r in __divNn(length(inst), Threads.nthreads())
                Threads.@spawn foreach(i -> Base.setproperty!(i.o, atr, x), inst[r])
            end
            @sync
        else
            foreach(i -> Base.setproperty!(i.o, atr, x), inst)
        end
    end

Base.haskey(ns::__NSX_CodeMode, key::Symbol) = key ∈ propertynames(ns)

Base.propertynames(ns::__NSX_CodeMode, private=false) =
    tuple(Base.keys(_NSdict0)..., Base.fieldnames(typeof(ns))...)

Base.hasproperty(ns::__NSX_CodeMode, atr::Symbol) =
    Base.hasfield(typeof(ns), atr) || haskey(_NSdict0, atr)


Base.getproperty(ns::__NSX_CodeMode, atr::Symbol) =
    begin
        Base.hasfield(typeof(ns), atr) && (return Base.getfield(ns, atr))
        haskey(_NSdict0, atr) && (return _NSdict0[atr](ns))
        error("""This NS does not have a property named "$(atr)".""")
    end;

################
# __NSClsInstance{X}
################

struct __NSClsInstance{X} <: AbstNS
    __dict::OrderedDict{Symbol, AbstNSitem}
    __fix_lck::MVector{2, Bool}
    cls::NS

    __NSClsInstance{X}(cls) where X =
        new{X}(#= __dict    =# OrderedDict{Symbol, AbstNSitem}(),
               #= __fix_lck =# MVector{2, Bool}(false, false),
               #= cls       =# cls)
end

Base.getproperty(nsi::__NSClsInstance, atr::Symbol) =
    begin
        Base.hasfield(typeof(nsi), atr) && (return Base.getfield(nsi, atr))

        haskey(_NSdict0, atr) && (return _NSdict0[atr](nsi))

        d = nsi.__dict

        if haskey(d, atr)
            x = d[atr].obj;
            isa(x, Union{NSTagFunc{:prp}, NSTagFunc{:mth}}) && (return x(nsi))
            isa(x, NSTagFunc{:fnc}) && (return x.fnc)
            isa(x, NSTagFunc{:req}) &&
                (y = x(nsi);
                 d[atr] = (isa(d[atr], NScst_item) ? NScst_item : NSnoncst_item)(y);
                 return y)
            return x
        else
            haskey(nsi.cls, atr) && (return Base.getproperty(nsi.cls, atr))
            error("""This NS does not have a property named "$(atr)".""")
        end
    end

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

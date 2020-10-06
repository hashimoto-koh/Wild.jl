import Dates
import SHA

################
# NSCode
################

struct NSCode <: AbstNSCode
    __args::Tuple{Vararg{Symbol}}
    __kargs
    __code::Array{Tuple{Symbol,Any},1}
    __type
    __instances
    __link_instances::Bool
    __init::Array{Union{Nothing, NSTagFunc{:mth}}}
    __cls::NS
    _instances::Nothing
    _clr_instances::Nothing

    NSCode(args...; __link_instances=false, kargs...) =
        new(#= __args           =# args,
            #= __kargs          =# kargs,
            #= __code           =# [],
            #= __type           =# genNSX(),
            #= __instances      =# [],
            #= __link_instances =# __link_instances,
            #= __init           =# [nothing],
            #= __cls            =# NS(),
            #= _instances       =# nothing,
            #= _clr_instances   =# nothing)
end
#=
macro NSCode()
    return esc(:(NSCode(; __mdl=@__MODULE__)))
end
=#
function push_to_instance(o, atr, val)
    x = isa(val, NSCodecst_item) ? Base.getproperty(o, :cst) : o

    y = (isa(val, AbstNSCodeitem) && isa(val.obj, NSTagFunc)
         ? Base.getproperty(x, typeof(val.obj).parameters[1])
         : x)

    if !isa(val, AbstNSCodeitem)
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

(nsc::NSCode)(args...; kargs...) =
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

        for (atr, val) ∈ nsc.__code
            push_to_instance(o, atr, val)
        end

        nsc.__link_instances &&
            append!(nsc.__instances, [(a=args, k=values(kargs), o=o)])
        o
    end

Base.setproperty!(nsc::AbstNSCode, atr::Symbol, x) =
    begin
        hasfield(typeof(nsc), atr) &&
            (Base.setfield!(nsc, atr, x); return)

        atr == :init && (nsc.__init[1] = NSTagFunc{:mth}(x); return)

        haskey(_NSCodedict0, atr) &&
            Base.error("'" * string(atr) * "' can't be used for property")

        haskey(nsc.__cls, atr) &&
            (Base.setproperty!(nsc.__cls, atr, x); return)

        nsc.__link_instances &&
            [push_to_instance(i, atr, x) for (a, k, i) ∈ nsc.__instances]

        push!(nsc.__code, (atr, x))
    end

Base.getproperty(nsc::AbstNSCode, atr::Symbol) =
    begin
        Base.hasfield(typeof(nsc), atr) && (return Base.getfield(nsc, atr))

        haskey(_NSCodedict0, atr) && (return _NSCodedict0[atr](nsc))

        atr == :init &&
            (return (isnothing(nsc.__init[1])
                    ? (nsc.__init[1] = NSTagFunc{:mth}(__NS_func{gensym()}))
                     : nsc.__init[1]))

        Base.getproperty(nsc.__cls, atr)
    end

################
# NSCodeitem
################

abstract type AbstNSCodeitem end

struct NSCodecst_item{T} <: AbstNSCodeitem
    obj::T
end

mutable struct NSCodenoncst_item{T} <: AbstNSCodeitem
    obj::T
end

################
# NSCodeTag
################

struct NSCodeTag{T, C} ___NSC_nsc::AbstNSCode end

Base.getproperty(x::NSCodeTag, atr::Symbol) =
    begin
        Base.hasfield(typeof(x), atr) && (return Base.getfield(x, atr))
        f = __NS_func{gensym()}
        Base.setproperty!(x.___NSC_nsc, atr, _MakeItem(x, f))
        f
    end

Base.setproperty!(tag::NSCodeTag, atr::Symbol, f) =
        (Base.hasfield(typeof(tag), atr)
         ? Base.setproperty!(tag, atr, f)
         : Base.setproperty!(tag.___NSC_nsc, atr, _MakeItem(tag,f)))

################
# NSCodecst
################

struct NSCodecst{T <: AbstNSCode} ___NSC_nsc::T end

Base.getproperty(cst::NSCodecst, atr::Symbol) =
    begin
        hasfield(typeof(cst), atr) && (return Base.getfield(cst, atr))
        NSCodeTag{atr, true}(cst.___NSC_nsc)
    end

Base.setproperty!(cst::NSCodecst, atr::Symbol, o) =
    Base.setproperty!(cst.___NSC_nsc, atr, NSCodecst_item(o))

_MakeItem(x::NSCodecst, o) = NSCodecst_item(o)

################
# NSCodeTagFunc
################

struct NSCodeTagFunc{T, C} nsc::AbstNSCode end
_MakeItem(x::NSCodeTag{T,false}, f) where T = NSCodenoncst_item(NSTagFunc{T}(f))
_MakeItem(x::NSCodeTag{T, true}, f) where T = NSCodecst_item(NSTagFunc{T}(f))

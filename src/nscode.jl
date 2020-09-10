import Dates
import SHA

################
# AbstNSCode
################

abstract type AbstNSCode end

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
    __init::Array{Function}

    _instances::Nothing
    _clr_instances::Nothing

    NSCode(args...; __link_instances=false, kargs...) =
        new(#= __args           =# args,
            #= __kargs          =# kargs,
            #= __code           =# [],
            #= __type           =# nsgen(),
            #= __instances      =# [],
            #= __link_instances =# __link_instances,
            #= __init           =# [(o ; ka...) -> (for (atr, val) in ka
                                                        Base.setproperty!(o, atr, val)
                                                    end)],
            #= _instances       =# nothing,
            #= _clr_instances   =# nothing)
end

function push_to_instance(o, atr, val)
    x = isa(val, NSCodecst_item) ? Base.getproperty(o, :cst) : o

    if isa(val, AbstNSCodeitem)
        if isa(val.obj, Dfn)
            y = Base.getproperty(x, :dfn)
        elseif isa(val.obj, Prp)
            y = Base.getproperty(x, :prp)
        elseif isa(val.obj, Mth)
            y = Base.getproperty(x, :mth)
        else
            y = x
        end
    else
        y = x
    end

    if !isa(val, AbstNSCodeitem)
        if atr == :exe
            val(y)
        else
            Base.setproperty!(y, atr, val)
        end
    elseif !hasfield(typeof(val.obj), :fnc)
        Base.setproperty!(y, atr, val.obj)
    else
        Base.setproperty!(y, atr, val.obj.fnc)
    end
end

(nsc::NSCode)(args...; kargs...) =
    begin
        o = nsc.__type()

        na = length(nsc.__args)
        nka = length(nsc.__kargs)

        length(args) < na &&
            Base.error("number of args should be equal to or larger than $na")

        for (atr, val) in zip(nsc.__args, args[1:na])
            Base.setproperty!(o, atr, val)
        end

        for (atr, val) in nsc.__kargs
            Base.setproperty!(o, atr, atr in keys(kargs) ? kargs[atr] : val)
        end

        nsc.__init[1](o, args[na+1:end]...;
                      Dict((k,v)
                           for (k,v) in kargs if !(k in keys(nsc.__kargs)))...)

        for (atr, val) in nsc.__code
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

        atr == :init &&
            (nsc.__init[1] = x; return)

        atr in (:cst, :dfn, :prp, :mth) &&
            Base.error("'" * string(:atr) * "' can't be used for property")

        nsc.__link_instances &&
            tfary(i->push_to_instance(i, atr, x),
                  (i for (a, k, i) in nsc.__instances))

        append!(nsc.__code, [(atr, x)])
    end

Base.getproperty(nsc::AbstNSCode, atr::Symbol) =
    begin
        #=
        if atr == :exe return f -> Base.setproperty!(nsc, atr, f) end
        =#

        atr == :cst && (return NSCodecst(nsc))

        atr == :dfn && (return NSCodedfn(nsc))
        atr == :prp && (return NSCodeprp(nsc))
        atr == :mth && (return NSCodemth(nsc))

        atr == :_instances && (return [i for (a, k, i) in nsc.__instances])
        atr == :_clr_instances &&
            (deleteat!(nsc.__instances, 1:length(nsc.__instances)); return)

        Base.getfield(nsc, atr)
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
# AbstNSCodetag
################

abstract type AbstNSCodetag end

#=
Base.getproperty(tag::AbstNSCodetag, atr::Symbol) =
    (hasfield(typeof(tag), atr)
     ? Base.getfield(tag, atr)
     : o -> (Base.setproperty!(tag, atr, o); tag.nsc))
=#

Base.setproperty!(tag::AbstNSCodetag, atr::Symbol, f) =
    Base.setproperty!(tag.nsc, atr, _MakeItem(tag,f))


################
# NSCodecst
################

struct NSCodecst{T <: AbstNSCode} nsc::T end

Base.getproperty(cst::NSCodecst, atr::Symbol) =
    begin
        #=
        if hasfield(typeof(cst), atr)
            return Base.getfield(cst, atr)
        end;

        if atr == :dfn return NSCodecstdfn(cst.nsc) end
        if atr == :prp return NSCodecstprp(cst.nsc) end
        if atr == :mth return NSCodecstmth(cst.nsc) end

        o -> (Base.setproperty!(cst, atr, o); cst.nsc)
        =#

        atr == :dfn && (return NSCodecstdfn(cst.nsc))
        atr == :prp && (return NSCodecstprp(cst.nsc))
        atr == :mth && (return NSCodecstmth(cst.nsc))
        return Base.getfield(cst, atr)
    end

Base.setproperty!(cst::NSCodecst, atr::Symbol, o) =
    Base.setproperty!(cst.nsc, atr, NSCodecst_item(o))

_MakeItem(x::NSCodecst, o) = NSCodecst_item(o)

################
# NSCodedfn
################

struct NSCodedfn{T <: AbstNSCode} <: AbstNSCodetag nsc::T end
struct NSCodecstdfn{T <: AbstNSCode} <: AbstNSCodetag nsc::T end

_MakeItem(x::NSCodedfn, f) = NSCodenoncst_item(dfn(f))
_MakeItem(x::NSCodecstdfn, f) = NSCodecst_item(dfn(f))

################
# NSCodeprp
################

struct NSCodeprp{T <: AbstNSCode} <: AbstNSCodetag nsc::T end
struct NSCodecstprp{T <: AbstNSCode} <: AbstNSCodetag nsc::T end

_MakeItem(x::NSCodeprp, f) = NSCodenoncst_item(prp(f))
_MakeItem(x::NSCodecstprp, f) = NSCodecst_item(prp(f))

################
# NSCodemth
################

struct NSCodemth{T <: AbstNSCode} <: AbstNSCodetag nsc::T end
struct NSCodecstmth{T <: AbstNSCode} <: AbstNSCodetag nsc::T end

_MakeItem(x::NSCodemth, f) = NSCodenoncst_item(mth(f))
_MakeItem(x::NSCodecstmth, f) = NSCodecst_item(mth(f))

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

    NSCode(args...; __mdl=nothing, __link_instances=false, kargs...) =
        begin
            __mdl == nothing && (__mdl = @__MODULE__)
            name = Symbol("NSCodeGenType_" *
                          string(bytes2hex(SHA.sha256(string(time_ns())))))
            tp = (Core.eval(__mdl,
                            quote
                            import DataStructures: OrderedDict
                            import Wild: AbstNSitem

                            struct $name <: AbstNS
                            __dict::OrderedDict{Symbol, AbstNSitem}
                            __fix_lck::Array{Bool, 1}

                            $name() = new(OrderedDict{Symbol, AbstNSitem}(),
                                          [false, false])
                            end
                            end);
                  Core.eval(__mdl, name))

            new(args, kargs, [], tp, [], __link_instances,
                [(o ; ka...) -> (for (atr, val) in ka
                                 Base.setproperty!(o, atr, val)
                                 end
                                 )],
                nothing,
                nothing)
        end
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

        if(length(args) < na)
            Base.error("number of args should be equal to or larger than $na")
        end

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
        if hasfield(typeof(nsc), atr)
            Base.setfield!(nsc, atr, x)
            return
        end

        if atr == :init
            nsc.__init[1] = x
            return
        end

        if atr in (:cst, :dfn, :prp, :mth)
            Base.error("'" * string(:atr) * "' can't be used for property")
        end

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

        if atr == :cst return NSCodecst(nsc) end

        if atr == :dfn return NSCodedfn(nsc) end
        if atr == :prp return NSCodeprp(nsc) end
        if atr == :mth return NSCodemth(nsc) end

        if atr == :_instances; return [i for (a, k, i) in nsc.__instances]; end
        if atr == :_clr_instances
            deleteat!(nsc.__instances, 1:length(nsc.__instances))
            return
        end

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

        if atr == :dfn return NSCodecstdfn(cst.nsc) end
        if atr == :prp return NSCodecstprp(cst.nsc) end
        if atr == :mth return NSCodecstmth(cst.nsc) end
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

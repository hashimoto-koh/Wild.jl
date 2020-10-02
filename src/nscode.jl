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
    __init::Array{Union{Nothing, NSFnc}}
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

    if isa(val, AbstNSCodeitem)
        if isa(val.obj, NSDfn)
            y = Base.getproperty(x, :dfn)
        elseif isa(val.obj, NSReq)
            y = Base.getproperty(x, :req)
        elseif isa(val.obj, NSPrp)
            y = Base.getproperty(x, :prp)
        elseif isa(val.obj, NSFnc)
            y = Base.getproperty(x, :fnc)
        elseif isa(val.obj, NSMth)
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
    elseif isa(val.obj, AbstNSTagFunc)
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

        if atr == :init
            if isnothing(nsc.__init[1])
                nsc.__init[1] = NSFnc(x)
            else
                nsc.__init[1].push!(x)
            end
            return
        end

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

        haskey(nsc.__cls, atr) && (return Base.getproperty(nsc.__cls, atr))

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
        atr == :req && (return NSCodecstreq(cst.nsc))
        atr == :prp && (return NSCodecstprp(cst.nsc))
        atr == :fnc && (return NSCodecstfnc(cst.nsc))
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

_MakeItem(x::NSCodedfn, f) = NSCodenoncst_item(NSDfn(f))
_MakeItem(x::NSCodecstdfn, f) = NSCodecst_item(NSDfn(f))

################
# NSCodereq
################

struct NSCodereq{T <: AbstNSCode} <: AbstNSCodetag nsc::T end
struct NSCodecstreq{T <: AbstNSCode} <: AbstNSCodetag nsc::T end

_MakeItem(x::NSCodereq, f) = NSCodenoncst_item(NSReq(f))
_MakeItem(x::NSCodecstreq, f) = NSCodecst_item(NSReq(f))

################
# NSCodeprp
################

struct NSCodeprp{T <: AbstNSCode} <: AbstNSCodetag nsc::T end
struct NSCodecstprp{T <: AbstNSCode} <: AbstNSCodetag nsc::T end

_MakeItem(x::NSCodeprp, f) = NSCodenoncst_item(NSPrp(f))
_MakeItem(x::NSCodecstprp, f) = NSCodecst_item(NSPrp(f))

################
# NSCodefnc
################

struct NSCodefnc{T <: AbstNSCode} <: AbstNSCodetag nsc::T end
struct NSCodecstfnc{T <: AbstNSCode} <: AbstNSCodetag nsc::T end

_MakeItem(x::NSCodefnc, f) = NSCodenoncst_item(NSFnc(f))
_MakeItem(x::NSCodecstfnc, f) = NSCodecst_item(NSFnc(f))

################
# NSCodemth
################

#=
abstract type AbstNSCodemth <: AbstNSCodetag end

Base.getproperty(x::AbstNSCodemth, atr::Symbol) = begin
    Base.hasfield(typeof(x), atr) && (return Base.getfield(x, atr))

    if !haskey(x.nsc, atr)
        Base.setproperty!(x.nsc,
                          atr,
                          Mth((f() = nothing;
                               Base.delete_method(Base.which(f, Tuple{}));
                               f)))
        return Base.getproperty(Base.getproperty(x.nsc, :mth), atr)
    end

    if isa(x.ns.__dict[atr], NSCodenoncst_item)
        isa(x.nsc.__dict[atr].obj, Mth) && (return x.nsc.__dict[atr].obj.fnc)

        x.nsc.__dict[atr] = Mth((f() = nothing;
                               Base.delete_method(Base.which(f, Tuple{}));
                               f))
        return Base.getproperty(Base.getproperty(x.nsc, :mth), atr)
    end

    Base.error("'" * string(:atr) * "' is const, so it can't be reassigned.")
end
=#

struct NSCodemth{T <: AbstNSCode} <: AbstNSCodetag nsc::T end
struct NSCodecstmth{T <: AbstNSCode} <: AbstNSCodetag nsc::T end

_MakeItem(x::NSCodemth, f) = NSCodenoncst_item(NSMth(f))
_MakeItem(x::NSCodecstmth, f) = NSCodecst_item(NSMth(f))

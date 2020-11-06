import Dates
import SHA
import StaticArrays.SVector

################
# AbstNSCls
################

abstract type AbstNSCls <: Function end

################
# _NSCls
################

struct _NSCls{TYPE} <: AbstNSCls
    __args::Tuple{Vararg{Symbol}}
    __kargs
    __cls::NS #(TYPE <: NSClsInstance ? NS : Nothing)
    __code::__NSX_CodeMode
    __type::DataType
    __instances
    __link_instances::Bool
    __init::Vector{Union{Nothing, NSTagFunc{:mth}}}
    __post::Vector{Union{Nothing, NSTagFunc{:mth}}}

    _NSCls{TYPE}(args...; __link_instances=false, kargs...) where TYPE =
        begin
            nsc = new{TYPE}(#= __args           =#
                            args,
                            #= __kargs          =#
                            kargs,
                            #= __cls            =#
                            NS(), #(TYPE <: NSClsInstance ? NS : Nothing)(),
                            #= __code           =#
                            __NSX_CodeMode(),
                            #= __type           =#
                            TYPE,
                            #= __instances      =#
                            [],
                            #= __link_instances =#
                            __link_instances,
                            #= __init           =#
                            [nothing],
                            #= __post           =#
                            [nothing])
            push!(nsc.__code.__instances, nsc.__instances)
            nsc
        end
end

(nsc::_NSCls{<: __NSClsInstance})(args...; kargs...) =
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

        for (atr, val) ∈ nsc.__code.__code
            if atr == :exe
                Base.setproperty!(o, atr, val)
            else
                x = isa(val, NScst_item) ? Base.getproperty!(o, :cst) : o
                y = (isa(val.obj, NSTagFunc)
                     ? Base.getproperty(x, typeof(val.obj).parameters[1])
                     : x)
                z = isa(val.obj, NSTagFunc) ? val.obj.fnc : val.obj
                Base.setproperty!(y, atr, z)
            end
        end
        isnothing(nsc.__post[1]) || nsc.__post[1](o)();

        nsc.__link_instances &&
            append!(nsc.__instances, [(a=args, k=values(kargs), o=o)])
        o
    end

(nsc::_NSCls{<: NSX})(args...; kargs...) =
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

        for (atr, val) ∈ nsc.__code.__code
            if atr == :exe
                Base.setproperty!(o, atr, val)
            else
                x = isa(val, NScst_item) ? Base.getproperty!(o, :cst) : o
                y = (isa(val.obj, NSTagFunc)
                     ? Base.getproperty(x, typeof(val.obj).parameters[1])
                     : x)
                z = isa(val.obj, NSTagFunc) ? val.obj.fnc : val.obj
                Base.setproperty!(y, atr, z)
            end
        end
        isnothing(nsc.__post[1]) || nsc.__post[1](o)();

        nsc.__link_instances &&
            append!(nsc.__instances, [(a=args, k=values(kargs), o=o)])
        o
    end

Base.setproperty!(nsc::_NSCls{<: __NSClsInstance}, atr::Symbol, x) =
    begin
        hasfield(typeof(nsc), atr) && (Base.setfield!(nsc, atr, x); return)

        atr == :init && (nsc.__init[1] = NSTagFunc{:mth}(x); return)
        atr == :post && (nsc.__post[1] = NSTagFunc{:mth}(x); return)

        haskey(_NSClsdict0, atr) &&
            Base.error("'" * string(atr) * "' can't be used for property")

        nsc.__cls.haskey(atr) && (return Base.setproperty!(nsc.__cls, atr, x))
        Base.setproperty!(nsc.__code, atr, x)
    end

Base.setproperty!(nsc::_NSCls{<: NSX}, atr::Symbol, x) =
    begin
        hasfield(typeof(nsc), atr) && (Base.setfield!(nsc, atr, x); return)

        atr == :init && (nsc.__init[1] = NSTagFunc{:mth}(x); return)
        atr == :post && (nsc.__post[1] = NSTagFunc{:mth}(x); return)

        haskey(_NSClsdict0, atr) &&
            Base.error("'" * string(atr) * "' can't be used for property")

        Base.setproperty!(nsc.__code, atr, x)
    end

Base.propertynames(nsc::_NSCls{<:__NSClsInstance}, private=false) =
    tuple(Base.propertynames(nsc.__cls, private)...,
          Base.keys(_NSClsdict0)...,
          Base.fieldnames(typeof(nsc))...)

Base.propertynames(nsc::_NSCls{<:NSX}, private=false) =
    tuple(Base.keys(_NSClsdict0)...,
          Base.fieldnames(typeof(nsc))...)

Base.hasproperty(nsc::_NSCls{<: __NSClsInstance}, atr::Symbol) =
    Base.hasfield(typeof(nsc), atr) ||
    haskey(_NSClsdict0, atr) ||
    Base.hasproperty(nsc.__cls, atr)

Base.hasproperty(nsc::_NSCls{<: NSX}, atr::Symbol) =
    Base.hasfield(typeof(nsc), atr) ||
    haskey(_NSClsdict0, atr)

Base.getproperty(nsc::_NSCls{<: __NSClsInstance}, atr::Symbol) =
    begin
        Base.hasfield(typeof(nsc), atr) && (return Base.getfield(nsc, atr))
        haskey(_NSClsdict0, atr) && (return _NSClsdict0[atr](nsc))
        Base.getproperty(nsc.__cls, atr)
    end

Base.getproperty(nsc::_NSCls{<: NSX}, atr::Symbol) =
    begin
        Base.hasfield(typeof(nsc), atr) && (return Base.getfield(nsc, atr))
        haskey(_NSClsdict0, atr) && (return _NSClsdict0[atr](nsc))
        Base.error("""this NSCode does not have a property named '$(atr)'.""")
    end

NSCls(args...; __link_instanaces=false, kargs...) =
    _NSCls{NSClsInstance{gensym()}}(args...;
                                    __link_instanaces=__link_instanaces, kargs...)
NSCode(args...; __link_instanaces=false, kargs...) =
    _NSCls{NSX{gensym()}}(args...; __link_instanaces=__link_instanaces, kargs...)

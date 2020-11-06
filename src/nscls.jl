import Dates
import SHA
import StaticArrays.MVector

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
# _NSCls
################

struct _NSCls{TYPE} <: AbstNSCls
    __args::Tuple{Vararg{Symbol}}
    __kargs
    __cls::(TYPE<:NSClsInstance?NS:Nothing)
    __code::__NSX_CodeMode
    __type::DataType
    __instances::SVector{1, __NSX_CodeMode_CodeType}
    __link_instances::Bool
    __init::Vector{Union{Nothing, NSTagFunc{:mth}}}
    __post::Vector{Union{Nothing, NSTagFunc{:mth}}}

    _NSCls(args...; __link_instances=false, kargs...) =
        begin
            nsc = new(#= __args           =#
                      args,
                      #= __kargs          =#
                      kargs,
                      #= __cls            =#
                      (TYPE <: NSClsInstance ? NS : Nothing)(),
                      #= __code           =#
                      __NSX_CodeMode(),
                      #= __type           =#
                      TYPE,
                      #= __instances      =#
                      SVector{1,__NSX_CodeMode_CodeType}([__NSX_CodeMode_CodeType()]),
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

(nsc::_NSCls{TYPE})(args...; kargs...) where TYPE =
    begin
        o = TYPE <: NSClsInstance ? nsc.__type(nsc.__cls) : nsc.__type()

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

Base.setproperty!(nsc::_NSCls{TYPE}, atr::Symbol, x) where TYPE =
    begin
        hasfield(typeof(nsc), atr) &&
            (Base.setfield!(nsc, atr, x); return)

        atr == :init && (nsc.__init[1] = NSTagFunc{:mth}(x); return)
        atr == :post && (nsc.__post[1] = NSTagFunc{:mth}(x); return)

        haskey(_NSClsdict0, atr) &&
            Base.error("'" * string(atr) * "' can't be used for property")

        TYPE <: NSClsInstance &&
            nsc.__cls.haskey(atr) &&
            (return Base.setproperty!(nsc.__cls, atr, x))

        Base.setproperty!(nsc.__code, atr, x)
    end

Base.propertynames(nsc::_NSCls{TYPE}, private=false) where TYPE =
    if TYPE <: NSClsInstance
        tuple(Base.propertynames(nsc.__cls, private)...,
              Base.keys(_NSClsdict0)...,
              Base.fieldnames(typeof(nsc))...)
    else
        tuple(Base.keys(_NSClsdict0)...,
              Base.fieldnames(typeof(nsc))...)
    end

Base.hasproperty(nsc::_NSCls{TYPE}, atr::Symbol) where TYPE =
    if TYPE <: NSClsInstance
        Base.hasfield(typeof(nsc), atr) ||
            haskey(_NSClsdict0, atr) ||
            Base.hasproperty(nsc.__cls, atr)
    else
        Base.hasfield(typeof(nsc), atr) ||
            haskey(_NSClsdict0, atr)
    end

Base.getproperty(nsc::_NSCls{TYPE}, atr::Symbol) where TYPE =
    begin
        Base.hasfield(typeof(nsc), atr) && (return Base.getfield(nsc, atr))
        haskey(_NSClsdict0, atr) && (return _NSClsdict0[atr](nsc))
        if TYPE <: NSClsInstance
            Base.getproperty(nsc.__cls, atr)
        else
            Base.error("""this NSCode does not have a property named '$(atr)'.""")
        end
    end

NSCls(args...; _link_instanaces=false, kargs...) =
    _NSCls{NSClsInstance{gensym()}, true}
NSCode(args...; _link_instanaces=false, kargs...) =
    _NSCls{NSX{gensym()}, false}

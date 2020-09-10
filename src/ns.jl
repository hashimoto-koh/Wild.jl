import DataStructures.OrderedDict
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
const _NS_fields = Set([:_keys,
                        :_vals,
                        :_keyvals,
                        :_printkeyvals,
                        :_fixed,
                        :_lcked,
                        :_frzed,
                        :_fix,
                        :_unfix,
                        :_lck,
                        :_unlck,
                        :_frz,
                        :_unfrz,
                        :_cst_keys,
                        :_noncst_keys,
                        :_clr,
                        :_copy,
                        :import,
                        :export,
                        :deepimport,
                        :deepexport,
                        :load,
                        :save,
                        :haskey,
                        :del,
                        :cstize,
                        :decstize,
                        :cst,
                        :dfn,
                        :prp,
                        :mth,
                        :exe
                        ])

abstract type AbstNS end

################
# NS
################

struct NS <: AbstNS
    __dict::OrderedDict{Symbol, AbstNSitem}
    __fix_lck::Vector{Bool}

    NS() = new(#= __dict    =# OrderedDict{Symbol, AbstNSitem}(),
               #= __fix_lck =# [false, false])
end

################
# NSGen{X}
################

struct NSGen{X} <: AbstNS
    __dict::OrderedDict{Symbol, AbstNSitem}
    __fix_lck::Vector{Bool}

    NSGen{X}() where X = new{X}(#= __dict    =# OrderedDict{Symbol, AbstNSitem}(),
                                #= __fix_lck =# [false, false])
end

Base.setproperty!(ns::AbstNS, atr::Symbol, x) =
    begin
        if hasfield(typeof(ns), atr)
            Base.setfield!(ns, atr, x)
        elseif atr == :exe
            x(ns)
        elseif atr in _NS_fields
            Base.error("'" * string(:atr) * "' can't be used for property")
        elseif haskey(ns.__dict, atr)
            ns._fixed && Base.error("this NS is fixed!")
            ns.__dict[atr].obj = isa(x, AbstNSitem) ? x.obj : x
        else
            ns._lcked && Base.error("this NS is locked!")
            ns.__dict[atr] = isa(x, AbstNSitem) ? x : NSnoncst_item(x)
        end
        ns
    end

Base.haskey(o::AbstNS, key::Symbol) = key in o._keys

Base.propertynames(ns::AbstNS, private=false) =
    tuple(Base.keys(ns.__dict)...,
          _NS_fields...,
          Base.fieldnames(typeof(ns))...)

Base.hasproperty(ns::AbstNS, atr::Symbol) =
    Base.hasfield(typeof(ns), atr) ||
    (atr in _NS_fields) ||
    haskey(ns.__dict, atr)

Base.getproperty(ns::AbstNS, atr::Symbol) =
    begin
        Base.hasfield(typeof(ns), atr) && (return Base.getfield(ns, atr))

        if atr in _NS_fields
            ############# prps
            if string(atr)[1] == '_'
                atr == :_fixed && (return ns.__fix_lck[1])
                atr == :_fixed && (return ns.__fix_lck[1])
                atr == :_lcked && (return ns.__fix_lck[2])
                atr == :_frzed && (return all(ns.__fix_lck))

                atr == :_keys && (return Tuple(Base.keys(ns.__dict)))
                atr == :_vals &&
                    (return Tuple(x.obj for x in Base.values(ns.__dict)))

                atr == :_keyvals && (return (; zip(ns._keys, ns._vals)...))
                atr == :_printkeyvals &&
                    ([println(k, ": ", v) for (k,v) in pairs(ns._keyvals)]; return)

                atr == :_fix   && (ns.__fix_lck[1] = true;  return ns)
                atr == :_unfix && (ns.__fix_lck[1] = false; return ns)
                atr == :_lck   && (ns.__fix_lck[2] = true;  return ns)
                atr == :_unlck && (ns.__fix_lck[2] = false; return ns)
                atr == :_frz   &&
                    (ns.__fix_lck[1] = ns.__fix_lck[2] = true; return ns)
                atr == :_unfrz &&
                    (ns.__fix_lck[1] = ns.__fix_lck[2] = false; return ns)

                atr == :_clr && (ns.del(); return ns)

                atr == :_copy && (return deepcopy(ns))

                atr == :_cst_keys &&
                    (d = ns.__dict;
                     return [k for k in ns._keys if isa(d[k], NScst_item)])
                atr == :_noncst_keys &&
                    (d = ns.__dict;
                     return [k for k in ns._keys if isa(d[k], NSnoncst_item)])
            ############# mths
            else
                # g.import(h)
                #     : import all properties from h
                # g.import(h, :a, :b, :c)
                #     : import properties :a, :b, :c from h
                atr == :import &&
                    (return (g::AbstNS, a::Vararg{Symbol}) ->
                        begin
                            if length(a) > 0
                                for k in a
                                    ns.__dict[k] = g.__dict[k]
                                end
                            else
                                for (k, v) in pairs(g.__dict)
                                    ns.__dict[k] = v
                                end
                            end
                            ns
                        end)
                # g.export()
                #     : export all properties from g to new ns
                # g.export(:a, :b, :c) #
                #     : export properties :a, :b, :c from g to new ns
                atr == :export &&
                    (return (a::Vararg{Symbol}) ->
                        begin
                            g = typeof(ns)()
                            if length(a) > 0
                                for k in a
                                    g.__dict[k] = ns.__dict[k]
                                end
                            else
                                for (k, v) in pairs(ns.__dict)
                                    g.__dict[k] = v
                                end
                            end
                            g
                        end)
                atr == :deepimport &&
                    (return (g::AbstNS, a::Vararg{Symbol}) ->
                        begin
                            if length(a) > 0
                                for k in a
                                    ns.__dict[k] = deepcopy(g.__dict[k])
                                end
                            else
                                for (k, v) in pairs(g.__dict)
                                    ns.__dict[k] = deepcopy(v)
                                end
                            end
                            ns
                        end)
                atr == :deepexport &&
                    (return (a::Vararg{Symbol}) ->
                        begin
                            g = typeof(ns)()
                            if length(a) > 0
                                for k in a
                                    g.__dict[k] = deepcopy(ns.__dict[k])
                                end
                            else
                                for (k, v) in pairs(ns.__dict)
                                    g.__dict[k] = deepcopy(v)
                                end
                            end
                            g
                     end)
                # g.load("x.ns")
                #     : load "x.ns" and import all properties from it
                # g.load("x.ns", :a, :b, :c)
                #     : load "x.ns" and import properties :a, :b, :c from it
                atr == :load &&
                    (return (filename::AbstractString, atr::Vararg{Symbol};
                             forcename=false) ->
                     begin
                         if !forcename && (length(filename) < length("a.ns") ||
                                           filename[end-length(".ns")+1:end] != ".ns")
                             filename = filename * ".ns"
                         end
                         ns.import(Serialization.deserialize(filename), atr...)
                     end)
                atr == :save &&
                    (return (filename::AbstractString, atr::Vararg{Symbol};
                             forcename=false) ->
                     begin
                         if !forcename && (length(filename) < length("a.ns") ||
                                           filename[end-length(".ns")+1:end] != ".ns")
                             filename = filename * ".ns"
                         end
                         g = ns.export(atr...)
                         Serialization.serialize(filename, g)
                         g
                     end)
                atr == :haskey   && return NShaskey(ns)
                atr == :del      && return NSdel(ns)
                atr == :cstize   && return NScstize(ns)
                atr == :decstize && return NSdecstize(ns)

                # tags
                atr == :cst && return NScst(ns)
                atr == :prp && return NSprp(ns)
                atr == :mth && return NSmth(ns)
                atr == :dfn && return NSdfn(ns)
            end
            error("SOMETHING WRONG. THIS IS BUG!!!" )
        end

        if haskey((local d = ns.__dict), atr)
            x = d[atr].obj;
            isa(x, Union{Prp, Mth}) ? x(ns) : x
        else
            # x -> (Base.setproperty!(ns, atr, x); ns)
            error("""This NS does not have a property named "$(atr)".""")
        end
    end

################
# >>, >>>
################

Base.:>>( g::AbstNS, h::AbstNS) = h.import(g)
Base.:>>>(g::AbstNS, h::AbstNS) = h.deepimport(g)

################
# NShaskey
################
struct NShaskey{T <: AbstNS} <: Function ns::T end

Base.getproperty(x::NShaskey, atr::Symbol) =
    hasfield(typeof(x), atr) ? Base.getfield(x, atr) : (atr in x.ns._keys)

(x::NShaskey)(atr::Symbol) = atr in x.ns._keys
(x::NShaskey)(atr::Symbol...) = (keys = x.ns._keys; collect(a in keys for a in atr))

################
# NSdel
################

struct NSdel{T <: AbstNS} <: Function ns::T end

Base.getproperty(x::NSdel, atr::Symbol) =
    begin
        hasfield(typeof(x), atr) && (return Base.getfield(x, atr))

        x.ns._fixed && error("this NS is fixed!")
        x.ns._lcked && error("this NS is locked!")

        delete!(x.ns.__dict, atr)
        x.ns
    end

(x::NSdel)(atr::Symbol...) =
    begin
        if length(atr) == 0
            x.ns._fixed && error("this NS is fixed!")
            x.ns._lcked && error("this NS is locked!")
            empty!(x.ns.__dict)
        else
            for a in atr; Base.getproperty(x, a); end
        end
        x.ns
    end

################
# NScstize, NSdecstize
################

struct NScstize{T <: AbstNS} <: Function ns::T end
struct NSdecstize{T <: AbstNS} <: Function ns::T end

Base.getproperty(x::NScstize, atr::Symbol) =
    begin
        hasfield(typeof(x), atr) && (return Base.getfield(x, atr))

        x.ns._fixed && error("this NS is fixed!")

        isa(x.ns.__dict[atr], NSnoncst_item) &&
            (x.ns.__dict[atr] = NScst_item(x.ns.__dict[atr].obj))
        x.ns
    end

Base.getproperty(x::NSdecstize, atr::Symbol) =
    begin
        hasfield(typeof(x), atr) && (return Base.getfield(x, atr))

        x.ns._fixed && error("this NS is fixed!")

        isa(x.ns.__dict[atr], NScst_item) &&
            (x.ns.__dict[atr] = NSnoncst_item(x.ns.__dict[atr].obj))
        x.ns
    end

(x::Union{NScstize, NSdecstize})(atr::Symbol...) =
    begin
        length(atr) == 0 && (return x(x.ns._keys...))

        for a in atr; Base.getproperty(x, a); end
        x.ns
    end

################
# AbstNStag
################

abstract type AbstNStag end
#=
Base.getproperty(x::AbstNStag, atr::Symbol) =
    (hasfield(typeof(x), atr)
     ? Base.getfield(x, atr)
     : o -> (Base.setproperty!(x, atr, o); x.ns))
=#
Base.setproperty!(x::AbstNStag, atr::Symbol, f) =
    Base.setproperty!(x.ns, atr, _MakeItem(x, f))


################
# NScst
################

struct NScst{T <: AbstNS} ns::T end

Base.getproperty(x::NScst, atr::Symbol) =
    begin
        #=
        hasfield(typeof(x), atr) && (return Base.getfield(x, atr))

        atr == :dfn && (return NScstdfn(x.ns))
        atr == :prp && (return NScstprp(x.ns))
        atr == :mth && (return NScstmth(x.ns))

        o -> (Base.setproperty!(x, atr, o); x.ns)
        =#

        atr == :dfn && (return NScstdfn(x.ns))
        atr == :prp && (return NScstprp(x.ns))
        atr == :mth && (return NScstmth(x.ns))
        return Base.getfield(x, atr)
    end

Base.setproperty!(x::NScst, atr::Symbol, o) =
    Base.setproperty!(x.ns, atr, NScst_item(o))

################
# NSdfn
################

struct NSdfn{T <: AbstNS} <: AbstNStag ns::T end

struct NScstdfn{T <: AbstNS} <: AbstNStag ns::T end

_MakeItem(x::NSdfn, f) = NSnoncst_item(f(x.ns))
_MakeItem(x::NScstdfn, f) = NScst_item(f(x.ns))

################
# NSprp
################

struct NSprp{T <: AbstNS} <: AbstNStag ns::T end
struct NScstprp{T <: AbstNS} <: AbstNStag ns::T end

_MakeItem(x::NSprp, f) = NSnoncst_item(prp(f))
_MakeItem(x::NScstprp, f) = NScst_item(prp(f))

################
# NSmth
################
abstract type AbstNSmth <: AbstNStag end
struct _NSmthDummySingleton end

Base.getproperty(x::AbstNSmth, atr::Symbol) = begin
    Base.hasfield(typeof(x), atr) && (return Base.getfield(x, atr))

    if !haskey(x.ns, atr)
        Base.setproperty!(x.ns, atr,
                          Mth((f() = nothing; Base.delete_method(@which f()); f)))
        return Base.getproperty(Base.getproperty(x.ns, :mth), atr)
    end
    if isa(x.ns.__dict[atr], NSnoncst_item)
        return (isa(x.ns.__dict[atr].obj, Mth)
                ? x.ns.__dict[atr].obj.fnc
                : (x.del(atr); Base.getproperty(Base.getproperty(x.ns, :mth), atr)))
    end

    Base.error("'" * string(:atr) * "' is const, so it can't be reassigned.")
end

struct NSmth{T <: AbstNS} <: AbstNSmth ns::T end
struct NScstmth{T <: AbstNS} <: AbstNSmth ns::T end

_MakeItem(x::NSmth, f) = NSnoncst_item(mth(f))
_MakeItem(x::NScstmth, f) = NScst_item(mth(f))

################
# ns
################

ns(name::Union{Nothing, Symbol, AbstractString}=nothing) =
begin
    isnothing(name) &&
        (name = Symbol("NS_" * string(bytes2hex(SHA.sha256(string(time_ns()))))))
    NSGen{name}
end

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

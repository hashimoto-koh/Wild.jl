import DataStructures.OrderedDict

################
# NSitem
################

abstract type AbstNSitem end

struct NScst_item <: AbstNSitem
    obj
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

struct NS <: AbstNS
    __dict::OrderedDict{Symbol, AbstNSitem}
    __fix_lck::Vector{Bool}

    NS() = new(#= __dict    =# OrderedDict{Symbol, AbstNSitem}(),
               #= __fix_lck =# [false, false])
end

Base.setproperty!(ns::AbstNS, atr::Symbol, x) =
    begin
        hasfield(typeof(ns), atr) && (Base.setfield!(ns, atr, x); return)

        atr == :exe && (x(ns); return;)

        (atr in _NS_fields) &&
            Base.error("'" * string(:atr) * "' can't be used for property")

        if haskey(ns.__dict, atr)
            ns._fixed && Base.error("this NS is fixed!")
            ns.__dict[atr].obj = isa(x, AbstNSitem) ? x.obj : x
            return
        end

        ns._lcked && Base.error("this NS is locked!")
        ns.__dict[atr] = isa(x, AbstNSitem) ? x : NSnoncst_item(x)
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
            # prps
            if string(atr)[1] == '_'
                atr == :_fixed && (return ns.__fix_lck[1])
                atr == :_fixed && (return ns.__fix_lck[1])
                atr == :_lcked && (return ns.__fix_lck[2])
                atr == :_frzed && (return all(ns.__fix_lck))

                atr == :_keys && (return Tuple(Base.keys(ns.__dict)))
                atr == :_vals &&
                    (return Tuple(x.obj for x in Base.values(ns.__dict)))

                atr == :_keyvals && (return (; zip(ns._keys, ns._vals)...))

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
            else
                # mths
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

        haskey((local d = ns.__dict), atr) &&
            (x = d[atr].obj; return isa(x, Union{Prp, Mth}) ? x(ns) : x)

        # x -> (Base.setproperty!(ns, atr, x); ns)
        error("""This NS does not have a property named "$(atr)".""")
    end

################
# >>, <<, >>>, <<<
################

Base.:>>( g::AbstNS, h::AbstNS) = h.import(g)
Base.:<<( g::AbstNS, h::AbstNS) = g.import(h)
Base.:>>>(g::AbstNS, h::AbstNS) = h.deepimport(g)
Base.:<<<(g::AbstNS, h::AbstNS) = g.deepimport(h)

################
# NShaskey
################
struct NShaskey <: Function ns::AbstNS end

Base.getproperty(x::NShaskey, atr::Symbol) =
    hasfield(typeof(x), atr) ? Base.getfield(x, atr) : (atr in x.ns._keys)

(x::NShaskey)(atr::Symbol) = atr in x.ns._keys
(x::NShaskey)(atr::Symbol...) = (keys = x.ns._keys; collect(a in keys for a in atr))

################
# NSdel
################

struct NSdel <: Function ns::AbstNS end

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

struct NScstize <: Function ns::AbstNS end
struct NSdecstize <: Function ns::AbstNS end

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

struct NScst ns::AbstNS end

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

struct NSdfn <: AbstNStag ns::AbstNS end

struct NScstdfn <: AbstNStag ns::AbstNS end

_MakeItem(x::NSdfn, f) = NSnoncst_item(f(x.ns))
_MakeItem(x::NScstdfn, f) = NScst_item(f(x.ns))

################
# NSprp
################

struct NSprp <: AbstNStag ns::AbstNS end
struct NScstprp <: AbstNStag ns::AbstNS end

_MakeItem(x::NSprp, f) = NSnoncst_item(prp(f))
_MakeItem(x::NScstprp, f) = NScst_item(prp(f))

################
# NSmth
################

struct NSmth <: AbstNStag ns::AbstNS end
struct NScstmth <: AbstNStag ns::AbstNS end

_MakeItem(x::NSmth, f) = NSnoncst_item(mth(f))
_MakeItem(x::NScstmth, f) = NScst_item(mth(f))

################
# ns
################

ns(name::Union{Nothing, Symbol, AbstractString}=nothing,
   mdl::Union{Nothing, Module}=nothing) =
begin
    mdl == nothing && (mdl = @__MODULE__)
    if (mdl != @__MODULE__) && !isnothing(name)
        !isa(name, Symbol) && (name = Symbol(name))
    else
        name = Symbol("NSType_" * string(isnothing(name) ? Base.gensym() : name))
    end
    tp = (Core.eval(__mdl,
            quote
                import DataStructures: OrderedDict
                import Wild: AbstNSitem

                struct $name <: AbstNS
                    __dict::OrderedDict{Symbol, AbstNSitem}
                    __fix_lck::Vector{Bool}

                    $name() = new(OrderedDict{Symbol, AbstNSitem}(),
                                  [false, false])
                end
                end);
        Core.eval(__mdl, name))
    Base.invokelatest(tp)
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

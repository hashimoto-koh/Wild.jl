import CodeTransformation: addmethod!

################
# NShaskey
################
struct NShaskey{T <: AbstNS} <: Function ns::T end

Base.getproperty(x::NShaskey, atr::Symbol) =
    hasfield(typeof(x), atr) ? Base.getfield(x, atr) : (atr ∈ x.ns._keys)

(x::NShaskey)(atr::Symbol) = atr ∈ x.ns._keys
(x::NShaskey)(atr::Symbol...) = (keys = x.ns._keys; collect(a ∈ keys for a ∈ atr))

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
            for a ∈ atr; Base.getproperty(x, a); end
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

        d = x.ns.__dict

        haskey(d, atr) ||
            error("""This NS does not have a property named "$(atr)".""")

        isa(d[atr], NSnoncst_item) && (d[atr] = NScst_item(d[atr].obj))

        x.ns
    end

Base.getproperty(x::NSdecstize, atr::Symbol) =
    begin
        hasfield(typeof(x), atr) && (return Base.getfield(x, atr))

        x.ns._fixed && error("this NS is fixed!")

        d = x.ns.__dict

        haskey(d, atr) ||
            error("""This NS does not have a property named "$(atr)".""")

        isa(x.ns.__dict[atr], NScst_item) &&
            (x.ns.__dict[atr] = NSnoncst_item(x.ns.__dict[atr].obj))

        x.ns
    end

(x::Union{NScstize, NSdecstize})(atr::Symbol...) =
    begin
        length(atr) == 0 && (return x(x.ns._keys...))

        for a ∈ atr; Base.getproperty(x, a); end
        x.ns
    end

################
# NSTag
################

struct NSTag{T::Symbol, CST::Bool} ___NStag_ns::AbstNS end

struct __NS_func{T} end

Base.getproperty(x::NSTag, atr::Symbol) =
    begin
        Base.hasfield(typeof(x), atr) && (return Base.getfield(x, atr))

        ns = x.___NStag_ns

        if !ns.haskey(atr)
            f = __NS_func{gensym()}
            Base.setproperty!(x, atr, f)
            return f
        end

        o = ns.__dict[atr].obj
        to = typeof(o)
        if to <: NSTagFunc
            tx = typeof(x)
            tx <: NSTag && to.parameters[1] == tx.parameters[1] && (return o.fnc)

            isa(ns.__dict[atr], NScst_item) &&
                error(""""$(atr)" is const.""")

            ns._fixed &&
                error("""This NS is fixed!
                         It already has a property name $(atr)".""")

            ns.del(atr)
            return Base.getproperty(x, atr)
        end

        return Base.getfield(x, atr)
    end

Base.setproperty!(x::NSTag, atr::Symbol, f) =
        (Base.hasfield(typeof(x), atr)
         ? Base.setproperty!(x, atr, f)
         : Base.setproperty!(x.___NStag_ns, atr, _MakeItem(x, f)))

################
# NScst
################

struct NScst{T <: AbstNS} ns::T end

Base.getproperty(x::NScst, atr::Symbol) =
    (Base.hasfield(typeof(x), atr)
     ? Base.getfield(x, atr)
     : NSTag{atr, true}(x.ns))

Base.setproperty!(x::NScst, atr::Symbol, o) =
        (Base.hasfield(typeof(x), atr)
         ? Base.setproperty!(x, atr, f)
         : Base.setproperty!(x.ns, atr, NScst_item(o)))

_MakeItem(x::NSTag{T, false}, f) where T = NSnoncst_item(NSTagFunc{T}(f))
_MakeItem(x::NSTag{T, true},  f) where T = NScst_item(NSTagFunc{T}(f))
_MakeItem(x::NSTag{:dfn, false}, f) = NSnoncst_item(f(x.___NStag_ns))
_MakeItem(x::NSTag{:dfn, true},  f) = NScst_item(f(x.___NStag_ns))

###############################
# NSTagFunc
###############################

struct NSTagFunc{T} fnc end

(dfn::NSTagFunc{:dfn})(self) = dfn.fnc(self)
(req::NSTagFunc{:req})(self) = req.fnc(self)
(mth::NSTagFunc{:mth})(self) = (a...; ka...)->mth.fnc(self, a...; ka...)
(fnc::NSTagFunc{:fnc})(self) = (a...; ka...)->fnc.fnc(self, a...; ka...)
(prp::NSTagFunc{:prp})(self) = (a...)->prp.fnc(a...)

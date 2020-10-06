import CodeTransformation: addmethod!

################
# NShaskey
################
struct NShaskey{T <: AbstNS} <: Function ___NS_ns::T end

Base.getproperty(x::NShaskey, atr::Symbol) =
    hasfield(typeof(x), atr) ? Base.getfield(x, atr) : (atr ∈ x.___NS_ns._keys)

(x::NShaskey)(atr::Symbol) = atr ∈ x.___NS_ns._keys
(x::NShaskey)(atr::Symbol...) =
    (keys = x.___NS_ns._keys; collect(a ∈ keys for a ∈ atr))

################
# NSdel
################

struct NSdel{T <: AbstNS} <: Function ___NS_ns::T end

Base.getproperty(x::NSdel, atr::Symbol) =
    begin
        hasfield(typeof(x), atr) && (return Base.getfield(x, atr))

        x.___NS_ns._fixed && error("this NS is fixed!")
        x.___NS_ns._lcked && error("this NS is locked!")

        delete!(x.___NS_ns.__dict, atr)
        x.___NS_ns
    end

(x::NSdel)(atr::Symbol...) =
    begin
        if length(atr) == 0
            x.___NS_ns._fixed && error("this NS is fixed!")
            x.___NS_ns._lcked && error("this NS is locked!")
            empty!(x.___NS_ns.__dict)
        else
            for a ∈ atr; Base.getproperty(x, a); end
        end
        x.___NS_ns
    end

################
# NScstize, NSdecstize
################

struct NScstize{T <: AbstNS} <: Function ___NS_ns::T end
struct NSdecstize{T <: AbstNS} <: Function ___NS_ns::T end

Base.getproperty(x::NScstize, atr::Symbol) =
    begin
        hasfield(typeof(x), atr) && (return Base.getfield(x, atr))

        x.___NS_ns._fixed && error("this NS is fixed!")

        d = x.___NS_ns.__dict

        haskey(d, atr) ||
            error("""This NS does not have a property named "$(atr)".""")

        isa(d[atr], NSnoncst_item) && (d[atr] = NScst_item(d[atr].obj))

        x.___NS_ns
    end

Base.getproperty(x::NSdecstize, atr::Symbol) =
    begin
        hasfield(typeof(x), atr) && (return Base.getfield(x, atr))

        x.___NS_ns._fixed && error("this NS is fixed!")

        d = x.___NS_ns.__dict

        haskey(d, atr) ||
            error("""This NS does not have a property named "$(atr)".""")

        isa(x.___NS_ns.__dict[atr], NScst_item) &&
            (x.___NS_ns.__dict[atr] = NSnoncst_item(x.___NS_ns.__dict[atr].obj))

        x.___NS_ns
    end

(x::Union{NScstize, NSdecstize})(atr::Symbol...) =
    begin
        length(atr) == 0 && (return x(x.___NS_ns._keys...))

        for a ∈ atr; Base.getproperty(x, a); end
        x.___NS_ns
    end

################
# NSTag
################

struct NSTag{T, CST} ___NS_ns::AbstNS end

struct __NS_func{T} end

Base.getproperty(x::NSTag, atr::Symbol) =
    begin
        Base.hasfield(typeof(x), atr) && (return Base.getfield(x, atr))

        ns = x.___NS_ns

        if !ns.haskey(atr)
            f = __NS_func{gensym()}
            Base.setproperty!(ns, atr, _MakeItem(x, f))
            return f
        end

        o = ns.__dict[atr].obj
        to = typeof(o)
        to <: NSTagFunc && to.parameters[1] == typeof(x).parameters[1] &&
            (return o.fnc)

        isa(ns.__dict[atr], NScst_item) &&
            error(""""$(atr)" is const.""")
        ns._fixed &&
            error("""This NS is fixed! It already has a property name $(atr)".""")
        ns.del(atr)
        Base.getproperty(x, atr)
    end

Base.setproperty!(x::NSTag, atr::Symbol, f) =
        (Base.hasfield(typeof(x), atr)
         ? Base.setproperty!(x, atr, f)
         : Base.setproperty!(x.___NS_ns, atr, _MakeItem(x, f)))

################
# NScst
################

struct NScst{T <: AbstNS} ___NS_ns::T end

Base.getproperty(x::NScst, atr::Symbol) =
    (Base.hasfield(typeof(x), atr)
     ? Base.getfield(x, atr)
     : NSTag{atr, true}(x.___NS_ns))

Base.setproperty!(x::NScst, atr::Symbol, o) =
        (Base.hasfield(typeof(x), atr)
         ? Base.setproperty!(x, atr, f)
         : Base.setproperty!(x.___NS_ns, atr, NScst_item(o)))

_MakeItem(x::NSTag{T, false}, f) where T = NSnoncst_item(NSTagFunc{T}(f))
_MakeItem(x::NSTag{T, true},  f) where T = NScst_item(NSTagFunc{T}(f))
_MakeItem(x::NSTag{:dfn, false}, f) = NSnoncst_item(f(x.___NS_ns))
_MakeItem(x::NSTag{:dfn, true},  f) = NScst_item(f(x.___NS_ns))

###############################
# NSTagFunc
###############################

struct NSTagFunc{T} fnc end

(dfn::NSTagFunc{:dfn})(self) = dfn.fnc(self)
(req::NSTagFunc{:req})(self) = req.fnc(self)
(mth::NSTagFunc{:mth})(self) = (a...; ka...)->mth.fnc(self, a...; ka...)
(fnc::NSTagFunc{:fnc})(a...; ka...) = fnc.fnc(a...; ka...)
(prp::NSTagFunc{:prp})(a...) = prp.fnc(a...)

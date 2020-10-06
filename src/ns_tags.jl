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
Base.delete_method(methods(__NS_func{gensym()}).ms[1])

__NS_func__add(fnc, f) where T =
    begin
        println("103: ", methods(f).ms[1:end])
        println("104: ", methods(f).ms[1].sig)
        println("104: ", methods(f).ms[1].sig.parameters[2:end])

        for m in methods(f).ms[1:end]
            ex = reduce(*,
                        ["a$(i)::$(x),"
                         for (i,x) in enumerate(m.sig.parameters[2:end])],
                        init="$(__NS_func{fnc.parameters[1]})(")[1:end-1] *
                  "; ka...) = f("
            ex = reduce(*,
                        ["a$(i)," for (i,x) in enumerate(m.sig.parameters[2:end])],
                        init=ex)[1:end-1] * "; ka...)"
            println(ex)
            eval(Meta.parse(ex))
        end
    end

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
    begin
        Base.hasfield(typeof(x), atr) && (Base.setproperty!(x, atr, f); return)

        if !x.___NS_ns.haskey(atr)
            Base.setproperty!(x.___NS_ns, atr, _MakeItem(x, f))
            return
        end

        ns = x.___NS_ns
        o = ns.__dict[atr].obj
        if isa(o, NSTagFunc) && typeof(x).parameters[1] == typeof(o).parameters[1]
            __NS_func__add(ns.__dict[atr].obj.fnc, f)
        else
            ns.del(atr)
            Base.setproperty!(x, atr, f)
        end
    end

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

_MakeItem(x::NSTag{T, false}, f) where T =
    begin
        if f <: __NS_func
            return NSnoncst_item(NSTagFunc{T}(f))
        end
        g = __NS_func{gensym()}
        __NS_func__add(g, f)
        NSnoncst_item(NSTagFunc{T}(g))
    end

_MakeItem(x::NSTag{T, true},  f) where T =
    begin
        if f <: __NS_func
            return NScst_item(NSTagFunc{T}(f))
        end
        g = __NS_func{gensym()}
        __NS_func__add(g, f)
        NScst_item(NSTagFunc{T}(g))
    end
_MakeItem(x::NSTag{:dfn, false}, f) = NSnoncst_item(f(x.___NS_ns))
_MakeItem(x::NSTag{:dfn, true},  f) = NScst_item(f(x.___NS_ns))

###############################
# NSTagFunc
###############################

struct NSTagFunc{T} fnc end

NSDfn = NSTagFunc{:dfn}
NSReq = NSTagFunc{:req}
NSMth = NSTagFunc{:mth}
NSFnc = NSTagFunc{:fnc}
NSPrp = NSTagFunc{:prp}

(dfn::NSDfn)(self) = dfn.fnc(self)
(req::NSReq)(self) = req.fnc(self)
(mth::NSMth)(self) = (a...; ka...)->mth.fnc(self, a...; ka...)
(fnc::NSFnc)(a...; ka...) = fnc.fnc(a...; ka...)
(prp::NSPrp)(a...) = prp.fnc(a...)

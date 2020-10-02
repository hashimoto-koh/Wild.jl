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
# AbstNStag
################

abstract type AbstNStag end
Base.setproperty!(x::AbstNStag, atr::Symbol, f) =
    Base.setproperty!(x.ns, atr, _MakeItem(x, f))

################
# NScst
################

struct NScst{T <: AbstNS} ns::T end

Base.getproperty(x::NScst, atr::Symbol) =
    begin
        atr == :dfn && (return NScstdfn(x.ns))
        atr == :req && (return NScstreq(x.ns))
        atr == :prp && (return NScstprp(x.ns))
        atr == :fnc && (return NScstfnc(x.ns))
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
# NSreq
################

struct NSreq{T <: AbstNS} <: AbstNStag ns::T end

struct NScstreq{T <: AbstNS} <: AbstNStag ns::T end

_MakeItem(x::NSreq, f) = NSnoncst_item(nsreq(f))
_MakeItem(x::NScstreq, f) = NScst_item(nsreq(f))

################
# NSprp
################

struct NSprp{T <: AbstNS} <: AbstNStag ns::T end
struct NScstprp{T <: AbstNS} <: AbstNStag ns::T end

_MakeItem(x::NSprp, f) = NSnoncst_item(NSPrp(f))
_MakeItem(x::NScstprp, f) = NScst_item(NSPrp(f))

################
# NSfnc
################

struct NSfnc{T <: AbstNS} <: AbstNStag ns::T end
struct NScstfnc{T <: AbstNS} <: AbstNStag ns::T end

_MakeItem(x::NSfnc, f) = NSnoncst_item(NSFnc(f))
_MakeItem(x::NScstfnc, f) = NScst_item(NSFnc(f))

################
# NSmth
################
struct NSmth{T <: AbstNS} <: AbstNStag ns::T end
struct NScstmth{T <: AbstNS} <: AbstNStag ns::T end

_MakeItem(x::NSmth, f) = NSnoncst_item(NSMth(f))
_MakeItem(x::NScstmth, f) = NScst_item(NSMth(f))

###############################
# ABstNSTagFunc
###############################

abstract type AbstNSTagFunc <: Function end

Base.push!(fnc::AbstNSTagFunc, f::Function) =
    begin
        push!(fnc.fnclist, f)
        for (m,c) in zip(methods(f).ms, code_lowered(f))
            addmethod!(Tuple{typeof(fnc.fnc), m.sig.parameters[2:end]...}, c)
        end
        fnc
    end

Base.push!(fnc::T, f::T) where T <: AbstNSTagFunc = Base.push!(fnc, f.fnc)

Base.getproperty(fnc::AbstNSTagFunc, atr::Symbol) =
    begin
        atr == :push! && (return f -> Base.push!(fnc, f))
        return Base.getfield(fnc, atr)
    end

###############################
# NSDfn
###############################

mutable struct NSDfn{F <: Function} <: AbstNSTagFunc fnc::F end
(dfn::NSDfn)(self) = dfn.fnc(self)

###############################
# NSReq
###############################

mutable struct NSReq{F <: Function} <: AbstNSTagFunc fnc::F end
(req::NSReq)(self) = req.fnc(self)

###############################
# NSMth
###############################

mutable struct NSMth{F <: Function} <: AbstNSTagFunc fnc::F end
(mth::NSMth)(self) = (a...; ka...)->mth.fnc(self, a...; ka...)

###############################
# NSFnc
###############################

mutable struct NSFnc{F <: Function} <: AbstNSTagFunc
    fnc::F
    fnclist::Vector{Function}
    NSFnc(f::F) where F = new{F}(f, Vector{Function}([f]))
end
(fnc::NSFnc)(self) = (a...; ka...)->fnc.fnc(self, a...; ka...)

###############################
# NSPrp
###############################

mutable struct NSPrp{F <: Function} <: AbstNSTagFunc
    fnc::F
    fnclist::Vector{Function}
    NSPrp(f::F) where F <: Function = new{F}(f, Vector{Function}([f]))
end
(prp::NSPrp)(a...; ka...) = prp.fnc(a...; ka...)

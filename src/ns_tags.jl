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

        if haskey((local d = x.ns.__dict), atr)
            isa(d[atr], NSnoncst_item) && (d[atr] = NScst_item(d[atr].obj))
        else
            error("""This NS does not have a property named "$(atr)".""")
        end

        x.ns
    end

Base.getproperty(x::NSdecstize, atr::Symbol) =
    begin
        hasfield(typeof(x), atr) && (return Base.getfield(x, atr))

        x.ns._fixed && error("this NS is fixed!")

        if haskey((local d = x.ns.__dict), atr)
            isa(x.ns.__dict[atr], NScst_item) &&
                (x.ns.__dict[atr] = NSnoncst_item(x.ns.__dict[atr].obj))
        else
            error("""This NS does not have a property named "$(atr)".""")
        end

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

_MakeItem(x::NSreq, f) = NSnoncst_item(req(f))
_MakeItem(x::NScstreq, f) = NScst_item(req(f))

################
# NSprp
################

struct NSprp{T <: AbstNS} <: AbstNStag ns::T end
struct NScstprp{T <: AbstNS} <: AbstNStag ns::T end

_MakeItem(x::NSprp, f) = NSnoncst_item(prp(f))
_MakeItem(x::NScstprp, f) = NScst_item(prp(f))

################
# NSfnc
################

struct NSfnc{T <: AbstNS} <: AbstNStag ns::T end
struct NScstfnc{T <: AbstNS} <: AbstNStag ns::T end

_MakeItem(x::NSfnc, f) = NSnoncst_item(fnc(f))
_MakeItem(x::NScstfnc, f) = NScst_item(fnc(f))

################
# NSmth
################
struct NSmth{T <: AbstNS} <: AbstNStag ns::T end
struct NScstmth{T <: AbstNS} <: AbstNStag ns::T end

_MakeItem(x::NSmth, f) = NSnoncst_item(mth(f))
_MakeItem(x::NScstmth, f) = NScst_item(mth(f))
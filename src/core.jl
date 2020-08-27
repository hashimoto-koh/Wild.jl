###############################
# @dfn, @prp, @mth, @sprp
###############################

abstract type AbstTagFunc <: Function end

macro dfn(ex)
    return esc(ex.head == :(=)
               ? Expr(:(=), ex.args[1], Expr(:call, :Dfn, ex.args[2]))
               : Expr(:call, :Dfn, ex))
end

macro prp(ex)
    return esc(ex.head == :(=)
               ? Expr(:(=), ex.args[1], Expr(:call, :Prp, ex.args[2]))
               : Expr(:call, :Prp, ex))
end

macro mth(ex)
    return esc(ex.head == :(=)
               ? Expr(:(=), ex.args[1], Expr(:call, :Mth, ex.args[2]))
               : Expr(:call, :Mth, ex))
end

macro sprp(ex)
    return esc(ex.head == :(=)
               ? Expr(:(=), ex.args[1], Expr(:call, :SetPrp, ex.args[2]))
               : Expr(:call, :SetPrp, ex))
end

###############################
# @prpfnc, @mthfnc
###############################

abstract type AbstFunc <: AbstTagFunc end

abstract type AbstPrpFunc <: AbstFunc end

abstract type AbstMthFunc <: AbstFunc end

macro prpfnc(name)
    typename = Base.gensym()
    ex = quote
        struct $typename  <: AbstPrpFunc
            type::Type
        end
        $name = ($typename)(:($$typename))
    end
    esc(ex)
end

macro mthfnc(name)
    typename = Base.gensym()
    ex = quote
        struct $typename  <: AbstMthFunc
            type::Type
        end
        $name = ($typename)(:($$typename))
        (f::$typename)(x) = (a...; ka...) -> f(x, a...; ka...)
    end
    esc(ex)
end

###############################
# dfn, prp, mth, sprp
###############################

abstract type AbstClassFunc <: AbstTagFunc end

mutable struct Dfn{T <: Any} <: AbstClassFunc fnc::T end
(dfn::Dfn)(self) = dfn.fnc(self)
dfn = fnc -> Dfn(fnc)

mutable struct Prp{T <: Any} <: AbstClassFunc fnc::T end
(prp::Prp)(self) =
    hasmethod(prp.fnc, Tuple{typeof(self)}) ? prp.fnc(self) : prp.fnc()
(prp::Prp)() = prp.fnc()
prp = fnc -> Prp(fnc)

mutable struct Mth{T <: Any} <: AbstClassFunc fnc::T end
(mth::Mth)(self) = (a...; ka...)->mth.fnc(self, a...; ka...)
mth(fnc) = Mth(fnc)

mutable struct SetPrp{T <: Any} <: AbstClassFunc fnc::T end
(sprp::SetPrp)(self) = (a...; ka...)->sprp.fnc(self, a...; ka...)
sprp(fnc) = SetPrp(fnc)

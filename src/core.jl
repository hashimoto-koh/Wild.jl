###############################
# @dfn, @req, @prp, @mth, @sprp
###############################
#=
(Example)

@prp type = x -> Base.typeof(x)
[1,2,3].type == Array{Int64,1}

@mth sz = (x,i) -> size(x,i)
[1,2,3].sz(1) == 3

g = NS()
g.a = 3
@prp g.b = g -> 3 * g.a
@mth g.f = (g,x) ->  g.a + x
=#

abstract type AbstTagFunc <: Function end

macro dfn(ex)
    return esc(ex.head == :(=)
               ? Expr(:(=), ex.args[1], Expr(:call, :Dfn, ex.args[2]))
               : Expr(:call, :Dfn, ex))
end

macro req(ex)
    return esc(ex.head == :(=)
               ? Expr(:(=), ex.args[1], Expr(:call, :Req, ex.args[2]))
               : Expr(:call, :Req, ex))
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
#=
(Example)
@prpfnc dtype
(::dtype.type)(itr) = eltype(itr)
(::dtype.type)(itr::Base.Generator) = Base.return_types(itr.f, (dtype(itr.iter),))[1]
=#

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
# dfn, req, prp, mth, sprp
###############################

abstract type AbstClassFunc <: AbstTagFunc end

mutable struct Dfn{T <: Any} <: AbstClassFunc fnc::T end
(dfn::Dfn)(self) = dfn.fnc(self)
dfn = fnc -> Dfn(fnc)

mutable struct Req{T <: Any} <: AbstClassFunc fnc::T end
(req::Dfn)(self) = req.fnc(self)
req = fnc -> Req(fnc)

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

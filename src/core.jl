import CodeTransformation: addmethod!

_add_lmd!(fnc, lmd) =
begin
    mdl = methods(fnc).ms[1].module
    ex = :((::typeof($(fnc)))(a::$(methods(lmd).ms[1].sig.parameters[2:end][1]);
                              ka...) = $(lmd)(a, ka...))
    Core.eval(mdl, ex)
    fnc
end

_addmth!(::Nothing, mth::Function) =
begin
    mdl = methods(mth).ms[1].module
    f = [Core.eval(mdl,
                   :((a::Tuple{$(ms).sig.parameters[begin+1:end]...}; ka...) ->
                     $(mth)(a...; ka...)))
         for ms in methods(mth).ms]
    for g in f[begin+1:end]
        _add_lmd!(f[1], g)
    end
    f[1]
end

_addmth!(::Nothing, mth::AbstractVector{Function}) =
    _addmth!(_addmth!(nothing, mth[1]), mth[2:end])

_addmth!(f::Function, mth::Function) =
begin
    mdl = methods(f).ms[1].module
    for ms in methods(mth).ms
        ex = :((a::Tuple{$(ms).sig.parameters[begin+1:end]...}; ka...) ->
               $(mth)(a...; ka...))
        g = Core.eval(mdl, ex)
        _add_lmd!(f, g)
    end
    f
end

_addmth!(f::Function, mth::AbstractVector{Function}) =
begin
    for m in mth
        _addmth!(f, m)
    end
    f
end

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

macro fnc(ex)
    return esc(ex.head == :(=)
               ? Expr(:(=), ex.args[1], Expr(:call, :Fnc, ex.args[2]))
               : Expr(:call, :Fnc, ex))
end
#=
macro sprp(ex)
    return esc(ex.head == :(=)
               ? Expr(:(=), ex.args[1], Expr(:call, :SetPrp, ex.args[2]))
               : Expr(:call, :SetPrp, ex))
end
=#
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
(req::Req)(self) = req.fnc(self)
req = fnc -> Req(fnc)
#=
mutable struct Prp{T <: Any} <: AbstClassFunc fnc::T end
(prp::Prp)(self) =
    hasmethod(prp.fnc, Tuple{typeof(self)}) ? prp.fnc(self) : prp.fnc()
(prp::Prp)() = prp.fnc()
prp = fnc -> Prp(fnc)
=#
mutable struct Mth{T <: Any} <: AbstClassFunc fnc::T end
(mth::Mth)(self) = (a...; ka...)->mth.fnc(self, a...; ka...)
mth(fnc) = Mth(fnc)
#=
mutable struct SetPrp{T <: Any} <: AbstClassFunc fnc::T end
(sprp::SetPrp)(self) = (a...; ka...)->sprp.fnc(self, a...; ka...)
sprp(fnc) = SetPrp(fnc)
=#
###############################
# fnc
###############################

fnc(f; init=true) = (fc = Fnc(f); init ? fc.init! : fc)

mutable struct Fnc <: AbstClassFunc
    fnc::Union{Nothing, Function}
    fnclist::Vector{Function}
    Fnc(f) = new(nothing, [f])
end

Fnc(flst::Vector{Function}) = (f = Fnc(flst[1]); f.append!(flst[2:end]); f)
Fnc(f::Fnc) = Fnc(f.fnclist)

(f::Fnc)(self) = (a...; ka...) -> f.fnc((self, a...); ka...)

function Base.push!(f::Fnc, mth::Function)
    isnothing(f.fnc) || _addmth!(f.fnc, mth)
    push!(f.fnclist, mth)
end

function Base.append!(f::Fnc, mths::AbstractVector{Function})
    isnothing(f.fnc) || _addmth!(f.fnc, mths)
    append!(f.fnclist, mths)
    f
end

Base.getproperty(fnc::Fnc, atr::Symbol) =
begin
    atr == :init! && (fnc.fnc = _addmth!(nothing, fnc.fnclist); return fnc)
    atr == :push! && (return f -> push!(fnc, f))
    atr == :append! && (return fncs -> append!(fnc, fncs))
    Base.getfield(fnc, atr)
end

###############################
# prp
###############################

prp(f; init=true) = (pr = Prp(f); init ? pr.init! : pr)

mutable struct Prp <: AbstClassFunc
    fnc::Union{Nothing, Function}
    fnclist::Vector{Function}
    Prp(f) = new(nothing, [f])
end

Prp(flst::Vector{Function}) = (p = Prp(flst[1]); p.append!(flst[2:end]); p)
Prp(p::Prp) = Prp(p.fnclist)

function Base.push!(p::Prp, mth::Function)
    isnothing(p.fnc) || _addmth!(p.fnc, mth)
    push!(p.fnclist, mth)
end

function Base.append!(p::Prp, mths::AbstractVector{Function})
    isnothing(p.fnc) || _addmth!(p.fnc, mths)
    append!(p.fnclist, mths)
    p
end

Base.getproperty(fnc::Prp, atr::Symbol) =
begin
    atr == :init! && (fnc.fnc = _addmth!(nothing, fnc.fnclist); return fnc)
    atr == :push! && (return f -> push!(fnc, f))
    atr == :append! && (return fncs -> append!(fnc, fncs))
    Base.getfield(fnc, atr)
end

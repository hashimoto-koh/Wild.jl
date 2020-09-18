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
(req::Req)(self) = req.fnc(self)
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

###############################
# fnc
###############################

struct _FncWrapper <: Function
    f
    _FncWrapper(f) = new(f)
end

(fnc::_FncWrapper)(a...; ka...) = fnc.f(a...; ka...)

Base.getproperty(fnc::_FncWrapper, atr::Symbol) =
begin
    Base.hasfield(_FncWrapper, atr) && (return Base.getfield(fnc, atr))

    atr == :push! &&
        return (mth ->
                (eval(:($(fnc).f(a::Tuple{methods($(mth)).mt.defs.sig.parameters[2:end]...}; ka...) = $(mth)(a...; ka...))); return fnc))

    atr == :append! && (return mthds -> (for f in mthds push!(fnc, f) end; fnc))

    atr == :reset! &&
        (for m in methods(fnc.f) Base.delete_method(m) end; return fnc)

    Base.getfield(fnc, atr)
end

mutable struct Fnc <: AbstClassFunc
    fnclist::Vector{Function}
    fnc::_FncWrapper
    Fnc() = (new(Vector{Function}[], _FncWrapper(
        (() -> (f() = nothing;
                for m in methods(f) Base.delete_method(m) end;
                f))())))
end

Fnc(flst::Vector{Function}) = (fnc = Fnc(); fnc.append!(flst); fnc)
Fnc(f::Function) = (fnc = Fnc(); fnc.push!(f); fnc)

(fnc::Fnc)(self) = (a...; ka...) -> fnc.fnc(tuple(self, a...); ka...)
fnc(f) = Fnc(f)

function Base.push!(fnc::Fnc, mth::Function)
    push!(fnc.fnclist, mth)
    fnc.fnc.push!(mth)
    fnc
end

function Base.append!(fnc::Fnc, mths::AbstractVector{Function})
    for f in mths push!(fnc, f) end
    fnc
end

Base.getproperty(fnc::Fnc, atr::Symbol) =
begin
    Base.hasfield(Fnc, atr) && (return Base.getfield(fnc, atr))

    atr == :push! && (return f -> push!(fnc, f))
    atr == :append! && (return fncs -> append!(fnc, fncs))
    atr == :reset! &&
        (fnc.fnc.reset!;
         for f in fnc.fnclist push!(fnc.fnc, f) end;
         return fnc)
    atr == :nothing! && (fnc.fnc = _FncWrapper(nothing); return fnc)
    atr == :init! &&
        (f() = nothing;
         fnc.fnc = _FncWrapper(f);
         return fnc.reset!)

    Base.getfield(fnc, atr)
end

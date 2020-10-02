###############################
# _add_mth!
###############################

_add_lmd!(fnc, lmd; mdl=nothing) =
begin
    mdl = isnothing(mdl) ? methods(fnc).ms[1].module : mdl
    ex = :((::typeof($(fnc)))(a::(methods($(lmd)).ms[1].sig.parameters[2:end][1]);
                              ka...) = $(lmd)(a, ka...))
    Core.eval(mdl, ex)
    fnc
end

_addmth!(::Nothing, mth::Function; mdl=nothing) =
begin
    mdl = isnothing(mdl) ? methods(mth).ms[1].module : mdl
    f = [Core.eval(mdl,
                   :((a::Tuple{$(ms).sig.parameters[begin+1:end]...}; ka...) ->
                     $(mth)(a...; ka...)))
         for ms ∈ methods(mth).ms]
    for g ∈ f[begin+1:end]
        _add_lmd!(f[1], g)
    end
    f[1]
end

_addmth!(::Nothing, mth::AbstractVector{Function}; mdl=nothing) =
    _addmth!(_addmth!(nothing, mth[1]; mdl=mdl), mth[2:end])

_addmth!(f::Function, mth::Function; mdl=nothing) =
begin
    mdl = isnothing(mdl) ? methods(f).ms[1].module : mdl
    for ms ∈ methods(mth).ms
        ex = :((a::Tuple{$(ms).sig.parameters[begin+1:end]...}; ka...) ->
               $(mth)(a...; ka...))
        g = Core.eval(mdl, ex)
        _add_lmd!(f, g)
    end
    f
end

_addmth!(f::Function, mth::AbstractVector{Function}; mdl=nothing) =
begin
    for m ∈ mth
        _addmth!(f, m; mdl=mdl)
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

#=
macro dfn(ex)
    return esc(ex.head == :(=)
               ? :($(ex.args[1]) = Wild.dfn($(ex.args[2])))
               : :(Wild.dfn($(ex))))
end

macro req(ex)
    return esc(ex.head == :(=)
               ? :($(ex.args[1]) = Wild.req($(ex.args[2])))
               : :(Wild.req($(ex))))
end
=#
macro prp(ex)
    return esc(ex.head == :(=)
               ? Expr(:(=),
                      ex.args[1],
                      :(Wild.prp((a...; ka...) -> $(ex.args[2])(a...; ka...);
                                 mdl=@__MODULE__)))
               : :(Wild.prp((a...; ka...) -> $(ex)(a...; ka...); mdl=@__MODULE__)))
end

macro mth(ex)
    return esc(ex.head == :(=)
               ? :($(ex.args[1]) = Wild.mth($(ex.args[2])))
               : :(Wild.mth($(ex))))
end
#=
macro fnc(ex)
    return esc(ex.head == :(=)
               ? Expr(:(=),
                      ex.args[1],
                      :(Wild.fnc((a...; ka...) -> $(ex.args[2])(a...; ka...);
                                 mdl=@__MODULE__)))
               : :(Wild.fnc((a...; ka...) -> $(ex)(a...; ka...); mdl=@__MODULE__)))
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

abstract type AbstTagFunc <: Function end
abstract type AbstPrpFunc <: AbstTagFunc end
abstract type AbstMthFunc <: AbstTagFunc end

macro prpfnc(name)
    typename = Base.gensym()
    ex = quote
        struct $(typename)  <: AbstPrpFunc
            type::Type
        end
        $name = ($typename)(:($$typename))
    end
    esc(ex)
end

macro mthfnc(name)
    typename = Base.gensym()
    ex = quote
        struct $(typename)  <: AbstMthFunc
            type::Type
        end
        $name = ($typename)(:($$typename))
        (f::$typename)(x) = (a...; ka...) -> f(x, a...; ka...)
    end
    esc(ex)
end

###############################
# fnc
###############################

fnc(f; init=true, mdl=nothing) =
    (fc = Fnc(f); init ? fc.init!(mdl) : fc)

mutable struct Fnc <: AbstClassFunc
    fnc::Union{Nothing, Function}
    fnclist::Vector{Function}
    Fnc(f::Function) = new(nothing, [f])
end

Fnc(flst::Vector{Function}) = (f = Fnc(flst[1]); f.append!(flst[2:end]); f)
Fnc(f::Fnc) = Fnc(f.fnclist)

(f::Fnc)(self) = (a...; ka...) ->
    begin
        try
            f.fnc((self, a...); ka...)
        catch
            f.init!(methods(f.fnc).ms[1].module)
            Base.invokelatest(f.fnc, (self, a...); ka...)
        end
    end

function Base.push!(f::Fnc, mth::Function)
    isnothing(f.fnc) || _addmth!(f.fnc, mth)
    push!(f.fnclist, mth)
end

function Base.append!(f::Fnc, mths::AbstractVector{Function})
    isnothing(f.fnc) || _addmth!(f.fnc, mths)
    append!(f.fnclist, mths)
    f
end

Base.getproperty(f::Fnc, atr::Symbol) =
begin
    atr == :init! &&
        (return (mdl=nothing) ->
                (f.fnc = _addmth!(nothing, f.fnclist; mdl=mdl); return f))
    atr == :push! && (return mth -> push!(f, mth))
    atr == :append! && (return mths -> append!(f, mths))
    Base.getfield(f, atr)
end

###############################
# prp
###############################

prp(f; init=true, mdl=nothing) = (pr = Prp(f); init ? pr.init!(mdl) : pr)

mutable struct Prp <: AbstClassFunc
    fnc::Union{Nothing, Function}
    fnclist::Vector{Function}
    Prp(f::Function) = new(nothing, [f])
end

Prp(flst::Vector{Function}) = (p = Prp(flst[1]); p.append!(flst[2:end]); p)
Prp(p::Prp) = Prp(p.fnclist)
(p::Prp)(a...; ka...) =
    try
        p.fnc(a; ka...)
    catch
        p.init!(methods(p.fnc).ms[1].module)
        Base.invokelatest(p.fnc, a; ka...)
    end

function Base.push!(p::Prp, mth::Function)
    isnothing(p.fnc) || _addmth!(p.fnc, mth)
    push!(p.fnclist, mth)
end

function Base.append!(p::Prp, mths::AbstractVector{Function})
    isnothing(p.fnc) || _addmth!(p.fnc, mths)
    append!(p.fnclist, mths)
    p
end

Base.getproperty(p::Prp, atr::Symbol) =
begin
    atr == :init! &&
        (return (mdl=nothing) ->
                (p.fnc = _addmth!(nothing, p.fnclist; mdl=mdl); return p))
    atr == :push! && (return mth -> push!(p, mth))
    atr == :append! && (return mths -> append!(p, mths))
    Base.getfield(p, atr)
end

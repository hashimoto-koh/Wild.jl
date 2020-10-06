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
                      :(Wild.NSTagFunc{:prp}((a...; ka...) -> $(ex.args[2])(a...; ka...))))
               : :(Wild.NSPrp((a...; ka...) -> $(ex)(a...; ka...))))
end

macro mth(ex)
    return esc(ex.head == :(=)
               ? :($(ex.args[1]) = Wild.NSTagFunc{:mth}($(ex.args[2])))
               : :(Wild.NSTagFunc{:mth}($(ex))))
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

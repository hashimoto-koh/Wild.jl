###############################
# @dfn, @req, @prp, @mth, @sprp
###############################
#=
(Example)

@prp tp = x -> Base.typeof(x)
tp = @prp x -> Base.typeof(x)

[1,2,3].tp == Array{Int64,1}

@mth sz = (x,i) -> size(x,i)
sz = @mth (x,i) -> size(x,i)
[1,2,3].sz(1) == 3

g = NS()
g.a = 3
@prp g.b = g -> 3 * g.a
g.c = @prp g -> 3 * g.b
@prp g.d(g) = 3 * g.c

@mth g.f = (g,x) ->  g.a + x
g.g = @mth (g,x) ->  g.b + x
@mth g.h(g,x) =  g.c + x
=#

macro prp(ex)
    # f = @prp x -> 2x
    if ex.head != :(=)
        return esc(:(Wild.NSTagFunc{:prp}($(ex))))
    end

    #=
    # @prp f(x) = 2x
    if hasfield(typeof(ex.args[1]), :head) && ex.args[1].head == :call
        name = ex.args[1].args[1]
        ex.args[1].args[1] = gensym()
        ex2 = :($(name) = Wild.NSTagFunc{:prp}($(ex.args[1].args[1])))
        ex = Meta.parse(string(ex) * ";" * string(ex2))
        return esc(ex)
    end
    =#

    # @prp f = x -> 2x
    return esc(:($(ex.args[1]) = Wild.NSTagFunc{:prp}($(ex.args[2]))))
end

macro mth(ex)
    # f = @mth (x,y) -> x+y
    if ex.head != :(=)
        return esc(:(Wild.NSTagFunc{:mth}($(ex))))
    end

    #=
    # @mth f = (x,y) -> x+y
    if hasfield(typeof(ex.args[1]), :head) && ex.args[1].head == :call
        name = ex.args[1].args[1]
        ex.args[1].args[1] = gensym()
        ex2 = :($(name) = Wild.NSTagFunc{:mth}($(ex.args[1].args[1])))
        ex = Meta.parse(string(ex) * ";" * string(ex2))
        return esc(ex)
    end
    =#

    # @mth f(x,y) = x+y
        return esc(:($(ex.args[1]) = Wild.NSTagFunc{:mth}($(ex.args[2]))))
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

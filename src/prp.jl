import DataStructures: DefaultDict

###############################
# @prp
###############################

struct __IsaPrp end
struct __IsnotaPrp end
@inline __isprp(x) = __IsnotaPrp()
@inline __asprp(f) = __asprp(__isprp(f), f)
@inline __asprp(::__IsaPrp, f) = o -> f(o)
@inline __asprp(::__IsnotaPrp, f) = o -> ((a...;ka...) -> f(o, a...; ka...))

export @prp

macro prp(ex)
    # f
    if isa(ex, Symbol)
        f = ex
        esc(:(@inline Wild.__isprp(::typeof($f)) = Wild.__IsaPrp()))
    # function f(x) 2x end
    elseif ex.head == :function
        f = ex.args[1].args[1]
        ff = :(@inline Wild.__isprp(::typeof($f)) = Wild.__IsaPrp())
        esc(Expr(:toplevel, ex, ff))
    elseif ex.head == :(=)
        # f(x) = 2x
        if isa(ex.args[1], Expr) && ex.args[1].head == :call
            f = ex.args[1].args[1]
            ff = :(@inline Wild.__isprp(::typeof($f)) = Wild.__IsaPrp())
            esc(Expr(:toplevel, ex, ff))
        # f = x -> 2x
        else
            f = ex.args[1]
            ff = :(@inline Wild.__isprp(::typeof($f)) = Wild.__IsaPrp())
            esc(Expr(:toplevel, ex, ff))
        end
    else
        f = ex
        esc(:(@inline Wild.__isprp(::typeof($f)) = Wild.__IsaPrp()))
    end
end

@prp Base.methods
@prp Base.inv
@prp Base.real
@prp Base.imag
@prp Base.reim
@prp Base.abs
@prp Base.abs2
@prp Base.conj
@prp Base.angle
@prp Base.cis
@prp Base.extrema
@prp Base.minimum
@prp Base.maximum
@prp Base.one
@prp Base.zero
@prp Base.keys
@prp Base.values
@prp Base.typeof
@prp Base.println
@prp Base.length
@prp Base.adjoint
@prp Base.transpose

###############################
# prpdict
###############################

mutable struct __Tree
    t::Type
    p::Union{Nothing, __Tree}
    c::Vector{__Tree}
end
__Tree(t::Type) = __Tree(t, nothing, __Tree[])
__Tree(t::Type, p) = __Tree(t, p, __Tree[])
__Tree(t::Type, p, c::Type) = __Tree(t, p, __Tree[__Tree(c, t)])

@inline __Tree_is_child(t1::__Tree, t2::__Tree) = t1.t <: t2.t
@inline __Tree_is_child(t1::__Tree, t2::Type) = t1.t <: t2
@inline __Tree_is_child(t1::Type, t2::__Tree) = t1 <: t2.t
@inline __Tree_is_child(t1::Type, t2::Type) = t1 <: t2

@inline __Tree_is_parent(t1::__Tree, t2::__Tree) = t2.t <: t1.t
@inline __Tree_is_parent(t1::__Tree, t2::Type) = t2 <: t1.t
@inline __Tree_is_parent(t1::Type, t2::__Tree) = t2.t <: t1
@inline __Tree_is_parent(t1::Type, t2::Type) = t2 <: t1

__Tree_insert(tr::__Tree, t::Type) =
begin
    __Tree_is_parent(t, tr) && (return __Tree(t, nothing, tr))
    !__Tree_is_child(t, tr) && error("something wrong")

    for (i,x) in enumerate(tr.c)
        if __Tree_is_child(t, x)
            __Tree_insert(x, t)
            return tr
        elseif __Tree_is_parent(t, x)
            oldtree = tr.c[i]
            newtree = __Tree(t, tr, [oldtree])
            oldtree.p = newtree
            tr.c[i] = newtree
            return tr
        end
    end
    push!(tr.c, __Tree(t, tr))
    tr
end

__Tree_path(tr::__Tree, t::Type, path=Type[]) =
begin
    push!(path, tr.t)
    tr.t == t && (return path)
    for tt in tr.c
        t <: tt.t && (return __Tree_path(tt, t, path))
    end
    path
end

__prpdct_type_tree = __Tree(Any)
__prpdct_path_dct = Dict{Type, Vector{Type}}()
__prpdct_path_dct[Any] = [Any]
__prpdct_type_list = [Number,
                      AbstractArray,
                      AbstractRange,
                      AbstractString,
                      Function,
                      Base.Generator,
                      Iterators.ProductIterator,
                      ]
for T in __prpdct_type_list
    __Tree_insert(__prpdct_type_tree, T)
end
for T in __prpdct_type_list
    __prpdct_path_dct[T] = reverse(__Tree_path(__prpdct_type_tree, T))
end

__PrpDct = Dict{Symbol, Function}
struct __getprp_dct <: Function _dct::Dict{Type, __PrpDct} end
Base.getindex(d::__getprp_dct, T::Type) = d._dct[T]
Base.setindex!(d::__getprp_dct, x::__PrpDct, T::Type) = Base.setindex!(d._dct, x, T)

getprp_dct = __getprp_dct(Dict{Type, __PrpDct}())

for T in [Any,
          Number,
          AbstractArray,
          AbstractRange,
          AbstractString,
          Function,
          Base.Generator,
          Iterators.ProductIterator,
          ]
    getprp_dct[T] = __PrpDct()
    Base.getproperty(o::T, atr::Symbol) =
        begin
            hasfield(typeof(o), atr) && (return Base.getfield(o, atr))
            for t in __prpdct_path_dct[T]
                haskey(getprp_dct[t], atr) && (return getprp_dct[t][atr](o))
            end
            __asprp(Base.eval(Base.Main, atr))(o)
        end

    Base.hasproperty(o::T, atr::Symbol) =
        begin
            hasfield(typeof(o), atr) && (return true)
            for t in __prpdct_path_dct[T]
                haskey(getprp_dct[t], atr) && (return true)
            end
            false
        end
    Base.propertynames(o::T, private=false) =
        tuple(fieldnames(typeof(o))...,
              vcat([collect(keys(getprp_dct[t]))
                    for t in __prpdct_path_dct[T]]...)...)
end

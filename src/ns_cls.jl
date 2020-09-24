#=
### Example

c = NSCls(:Ex, true)
c.n = 0

c.fnc.init = (cls, g, i, x, y, z) ->
begin
    g.i = i
    (g.a, g.b, g.c) = x, y, z
    g.prp.d = g -> g.a + g.b + g.c
    g.req.e = g -> 10 * g.d
    cls.n += 1
end

c.fnc.init = (ns, g, i, x, y) -> c.init(g, i,, x, y, 10x+y)

g1 = c(3,4,5)
g2 = c(30,4)

c.toinstances = g ->
begin
    g.x= 0:0.01:3π
    g.fnc.f = (g,f) -> pl.x(g.x).plot(f.(g.x * g.a))
end

c.toinstances = g -> println(g.e)

c.toinstances = g -> g.f(cos);

=#

struct AbstNSCls <: AbstNS end

struct NSCls <: AbstNSCls
    __dict::OrderedDict{Symbol, AbstNSitem}
    __fix_lck::MVector{2, Bool}
    __type::Type
    __instances::Union{Nothing, Vector{AbstNS}}
    NSCls(name=nothing, keep_instances=false) =
        begin
            name = (isnothing(name)
                    ? Symbol("NS_"*string(bytes2hex(SHA.sha256(string(time_ns())))))
                    : Symbol(name))
            Type = NSGen{name}
            x = new(#= __dict    =#
                    OrderedDict{Symbol, AbstNSitem}(),
                    #= __fix_lck =#
                    MVector{2, Bool}(false, false),
                    #= __type    =#
                    Type,
                    #= __instances =#
                    keep_instances ? Vector{Type}() : nothing)
            x.cst.sprp.toinstances = (cls, f) -> isnothing(cls.__instances) ||
                                                 [f(g) for g in cls.__instances]
            x
        end
end

(cls::NSCls)(a...; ka...) =
begin
    g = cls.__type()
    isnothing(cls.__instances) || push!(cls.__instances, g)
    haskey(cls, :init) && cls.init(g, a...; ka...)
    g
end

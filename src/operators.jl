# module operators

export ⊕, ⊗

###############################
# operators
###############################

#=
[1] (exponentiation)
^ ↑ ↓ ⇵ ⟰ ⟱ ⤈ ⤉ ⤊ ⤋ ⤒ ⤓ ⥉ ⥌ ⥍ ⥏ ⥑ ⥔ ⥕ ⥘ ⥙ ⥜ ⥝ ⥠ ⥡ ⥣ ⥥ ⥮ ⥯ ￪ ￬

[2] (unary)
+ - ! ~ ¬ √ ∛ ∜ ⋆ ± ∓

[3] (bitshift)
<< >> >>>

[4] (fraction)
//

[5] (multiplication)
* / ÷ % & ⋅ ∘ × |\\| ∩ ∧ ⊗ ⊘ ⊙ ⊚ ⊛ ⊠ ⊡ ⊓ ∗ ∙ ∤ ⅋ ≀ ⊼ ⋄ ⋆ ⋇ ⋉ ⋊ ⋋ ⋌ ⋏ ⋒ ⟑ ⦸ ⦼ ⦾ ⦿ ⧶ ⧷ ⨇ ⨰ ⨱ ⨲ ⨳ ⨴ ⨵ ⨶ ⨷ ⨸ ⨻ ⨼ ⨽ ⩀ ⩃ ⩄ ⩋ ⩍ ⩎ ⩑ ⩓ ⩕ ⩘ ⩚ ⩜ ⩞ ⩟ ⩠ ⫛ ⊍ ▷ ⨝ ⟕ ⟖ ⟗ ⨟

[6] (addition)
+ - |\|| ⊕ ⊖ ⊞ ⊟ |++| ∪ ∨ ⊔ ± ∓ ∔ ∸ ≏ ⊎ ⊻ ⊽ ⋎ ⋓ ⧺ ⧻ ⨈ ⨢ ⨣ ⨤ ⨥ ⨦ ⨧ ⨨ ⨩ ⨪ ⨫ ⨬ ⨭ ⨮ ⨹ ⨺ ⩁ ⩂ ⩅ ⩊ ⩌ ⩏ ⩐ ⩒ ⩔ ⩖ ⩗ ⩛ ⩝ ⩡ ⩢ ⩣

=#

# [1]
# f^x == f(x)
Base.:^(f, x) = x | functionalize(f)

# [2]
# ~f == functionalize(f)
# -f == a->functionalize(f)(a...)
# +f == a->functionalize(f).(a)
Base.:~(f) = functionalize(f)
Base.:-(f) = a -> functionalize(f)(a...)
Base.:+(f) = a -> functionalize(f).(a)

# [3]
# f // x == f(x)
Base.://(f, x) = x | functionalize(f)

# [4]
# f & g == f / g == x -> g(f(x))
Base.:&(f, g) = functionalize(g) ∘ functionalize(f)
Base.:/(f, g) = functionalize(g) ∘ functionalize(f)

# [5]
# x | f == f(x)
Base.:|(x, f) = (g = functionalize(f); Core.applicable(g, x) ? g(x) : g(x...))

# args(x...;ka...) | f == f(x...;ka...)
Base.:|(x::_Args, f) = x(f)

to_rng(i::Integer) = i>=1 ? (1:i) : (-1:-1:i)
to_rng(x) = x

###############################
# zip
###############################

@inline ⊕(x, y) = zip(to_rng(x), to_rng(y))
@inline ⊕(x::Base.Iterators.Zip, y) = zip(x.is..., to_rng(y))
@inline ⊕(x::Base.Iterators.Zip, y::Base.Iterators.Zip) = zip(x, y)
@inline ⊕(x...) = zip(x...)

###############################
# product
###############################

@inline ⊗(x, y) = Iterators.product(to_rng(x), to_rng(y))
@inline ⊗(x::Base.Iterators.ProductIterator, y) =
    Iterators.product(x.iterators..., to_rng(y))
@inline ⊗(x::Base.Iterators.ProductIterator, y::Base.Iterators.ProductIterator) =
    Iterators.product(x, y)
@inline ⊗(x...) = Iterators.product(x...)

#=
###############################
# concatenate
###############################

@inline ⊞(x) = ⊞(x...)
@inline ⊞(x::Tuple, y::Tuple) = tpljoin(x,y)
@inline ⊞(x::AbstractArray, y::AbstractArray) = aryjoin(x,y)

###############################
# fgen, fary, tfary, pfary
###############################

@inline ⩅(itr, fnc) = fgen(fnc, itr)
# @inline ⩂(fnc, itr) = fgen(fnc, itr)
@inline ⋓(itr, fnc) = fary(fnc, itr)
@inline ⩐(itr, fnc) = fary(fnc, itr; prgrs=true)
@inline ⩏(itr, fnc) = tfary(fnc, itr)
@inline ⊔(itr, fnc) = tfary(fnc, itr; prgrs=true)
@inline ⩖(itr, fnc) = pfary(fnc, itr)
@inline ⩒(itr, fnc) = pfary(fnc, itr; prgrs=true)
=#

# end

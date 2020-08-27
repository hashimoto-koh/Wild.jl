module Wild

Base.getproperty(o::Any, atr::Symbol) =
    (hasfield(typeof(o), atr)
     ? Base.getfield(o, atr)
     : Base.eval(Base.Main, atr)(o))
#     : (f = Base.eval(Base.Main, atr); (isa(f, AbstTagFunc) ? f : Mth(f))(o)))

end

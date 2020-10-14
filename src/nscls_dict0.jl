################
# AbstNSCode
################

abstract type AbstNSCls <: Function end

################
# NSClsdict0
################

const _NSClsdict0 = Dict{Symbol, Function}()

_NSClsdict0[:cls] = nsc -> nsc.__cls
_NSClsdict0[:ins] = nsc -> nsc.__code
_NSClsdict0[:init] = nsc -> nsc.__init[1]
_NSClsdict0[:post] = nsc -> nsc.__post[1]

_NSClsdict0[:cst] = nsc -> NSClscst(nsc)

_NSClsdict0[:dfn] = nsc -> NSClsTag{:dfn, false}(nsc)
_NSClsdict0[:req] = nsc -> NSClsTag{:req, false}(nsc)
_NSClsdict0[:prp] = nsc -> NSClsTag{:prp, false}(nsc)
_NSClsdict0[:fnc] = nsc -> NSClsTag{:fnc, false}(nsc)
_NSClsdict0[:mth] = nsc -> NSClsTag{:mth, false}(nsc)
_NSClsdict0[:var] = nsc -> NSClsTag{:var, false}(nsc)

_NSClsdict0[:_instances] = nsc -> [i for (a, k, i) ∈ nsc.__instances]
_NSClsdict0[:_clr_instances] =
    nsc -> (deleteat!(nsc.__instances, 1:length(nsc.__instances)); return)
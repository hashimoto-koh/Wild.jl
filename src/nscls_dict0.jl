################
# NSClsdict0
################

const _NSClsdict0 = Dict{Symbol, Function}()

_NSClsdict0[:type] = nsc -> nsc.__type

_NSClsdict0[:cls] = nsc -> nsc.__cls

_NSClsdict0[:init] = nsc -> nsc.__init[1]
_NSClsdict0[:post] = nsc -> nsc.__post[1]

_NSClsdict0[:cst] = nsc -> nsc.__code.cst
_NSClsdict0[:dfn] = nsc -> nsc.__code.dfn
_NSClsdict0[:req] = nsc -> nsc.__code.req
_NSClsdict0[:prp] = nsc -> nsc.__code.prp
_NSClsdict0[:fnc] = nsc -> nsc.__code.fnc
_NSClsdict0[:mth] = nsc -> nsc.__code.mth
_NSClsdict0[:var] = nsc -> nsc.__code

_NSClsdict0[:instances] = nsc -> [i for (a, k, i) ∈ nsc.__instances]
_NSClsdict0[:clr_instances!] =
    nsc -> (deleteat!(nsc.__instances, 1:length(nsc.__instances)); return)

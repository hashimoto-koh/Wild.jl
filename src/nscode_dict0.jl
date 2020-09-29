################
# AbstNSCode
################

abstract type AbstNSCode end

################
# NSCodedict0
################

const _NSCodedict0 = Dict{Symbol, Function}()

_NSCodedict0[:cls] = nsc -> nsc.__cls
_NSCodedict0[:init] = nsc -> nsc.__init[1]

_NSCodedict0[:cst] = nsc -> NSCodecst(nsc)

_NSCodedict0[:dfn] = nsc -> NSCodedfn(nsc)
_NSCodedict0[:req] = nsc -> NSCodereq(nsc)
_NSCodedict0[:prp] = nsc -> NSCodeprp(nsc)
_NSCodedict0[:fnc] = nsc -> NSCodefnc(nsc)
_NSCodedict0[:mth] = nsc -> NSCodemth(nsc)

_NSCodedict0[:_instances] = nsc -> [i for (a, k, i) ∈ nsc.__instances]
_NSCodedict0[:_clr_instances] =
    nsc -> (deleteat!(nsc.__instances, 1:length(nsc.__instances)); return)

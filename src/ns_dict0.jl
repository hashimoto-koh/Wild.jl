################
# AbstNS
################

abstract type AbstNS end

################
# NSdict0
################

const _NSdict0 = Dict{Symbol, Function}()

_NSdict0[:_fixed] = ns -> ns.__fix_lck[1]
_NSdict0[:_lcked] = ns -> ns.__fix_lck[2]
_NSdict0[:_frzed] = ns -> all(ns.__fix_lck)
_NSdict0[:_keys] = ns -> Tuple(Base.keys(ns.__dict))
_NSdict0[:_vals] = ns -> Tuple(x.obj for x ∈ Base.values(ns.__dict))
_NSdict0[:_keyvals] = ns -> (; zip(ns._keys, ns._vals)...)
_NSdict0[:_printkeyvals] =
    ns -> ([println(k, ": ", v) for (k,v) ∈ pairs(ns._keyvals)]; return)
_NSdict0[:_printkeytypes] =
    ns -> ([println(k, ": ", typeof(v)) for (k,v) ∈ pairs(ns._keyvals)]; return)
_NSdict0[:_fix] = ns -> (ns.__fix_lck[1] = true; ns)
_NSdict0[:_unfix] = ns -> (ns.__fix_lck[1] = false; ns)
_NSdict0[:_lck] = ns -> (ns.__fix_lck[2] = true;  ns)
_NSdict0[:_unlck] = ns -> (ns.__fix_lck[2] = false; ns)
_NSdict0[:_frz] = ns -> (ns.__fix_lck[1] = ns.__fix_lck[2] = true; ns)
_NSdict0[:_unfrz] = ns -> (ns.__fix_lck[1] = ns.__fix_lck[2] = false; ns)
_NSdict0[:_clr] = ns -> (ns.del(); ns)
_NSdict0[:_copy] = ns -> deepcopy(ns)
_NSdict0[:_cst_keys] =
    ns -> (d = ns.__dict; [k for k ∈ Base.keys(d) if isa(d[k], NScst_item)])
_NSdict0[:_noncst_keys] =
    ns -> (d = ns.__dict; [k for k ∈ Base.keys(d) if isa(d[k], NSnoncst_item)])
_NSdict0[:import] = ns ->
    ((g::AbstNS, a::Vararg{Symbol}; exclude=[], deep=false) ->
     begin
         d = ns.__dict
         gd = g.__dict
         if deep
             if length(a) > 0
                 for k ∈ a
                     k ∉ exclude && (d[k] = deepcopy(gd[k]))
                 end
             else
                 for (k, v) ∈ pairs(gd)
                     k ∉ exclude && (d[k] = deepcopy(v))
                 end
             end
         else
             if length(a) > 0
                 for k ∈ a
                     k ∉ exclude && (d[k] = gd[k])
                 end
             else
                 for (k, v) ∈ pairs(gd)
                     k ∉ exclude && (d[k] = v)
                 end
             end
         end
         ns
     end)
_NSdict0[:copyout] = ns ->
    ((a::Vararg{Symbol}; exclude=[], deep=false) ->
     begin
         g = typeof(ns)()
         d = ns.__dict
         gd = g.__dict
         if deep
             if length(a) > 0
                 for k ∈ a
                     k ∉ exclude &&
                         (gd[k] = (ns.iscst(k)
                                   ? NScst_item
                                   : NSnoncst_item)(deepcopy(d[k].obj)))
                 end
             else
                 for (k, w) ∈ pairs(d)
                     k ∉ exclude &&
                         (gd[k] = (ns.iscst(k)
                                   ? NScst_item
                                   : NSnoncst_item)(deepcopy(w.obj)))
                 end
             end
         else
             if length(a) > 0
                 for k ∈ a
                     k ∉ exclude &&
                         (gd[k] = (ns.iscst(k)
                                   ? NScst_item
                                   : NSnoncst_item)(d[k].obj))
                 end
             else
                 for (k, w) ∈ pairs(d)
                     k ∉ exclude &&
                         (gd[k] = (ns.iscst(k)
                                   ? NScst_item
                                   : NSnoncst_item)(w.obj))
                 end
             end
         end
         g
     end)
_NSdict0[:copyfrom] = ns ->
    ((g::AbstNS, a::Vararg{Symbol}; exclude=[], deep=false) ->
     # ns.import(g.copyout(a...; exclude=exclude, deep=deep))
     begin
         d = ns.__dict
         gd = g.__dict
         if deep
             if length(a) > 0
                 for k ∈ a
                    k ∉ exclude &&
                         (d[k] = (g.iscst(k)
                                  ? NScst_item
                                  : NSnoncst_item)(deepcopy(gd[k].obj)))
                 end
             else
                 for (k, w) ∈ pairs(gd)
                     k ∉ exclude &&
                         (d[k] = (g.iscst(k)
                                  ? NScst_item
                                  : NSnoncst_item)(deepcopy(w.obj)))
                 end
             end
         else
             if length(a) > 0
                 for k ∈ a
                     k ∉ exclude &&
                         (d[k] = (g.iscst(k)
                                  ? NScst_item
                                  : NSnoncst_item)(gd[k].obj))
                 end
             else
                 for (k, w) ∈ pairs(gd)
                     k ∉ exclude &&
                         (d[k] = (g.iscst(k)
                                  ? NScst_item
                                  : NSnoncst_item)(w.obj))
                 end
             end
         end
         ns
     end)
# g.export()
#     : export all properties from g to new ns
# g.export(:a, :b, :c) #
#     : export properties :a, :b, :c from g to new ns
_NSdict0[:export] = ns ->
    ((a::Vararg{Symbol}; exclude=[], deep=false) ->
     begin
         g = typeof(ns)()
         d = ns.__dict
         gd = g.__dict
         if deep
             if length(a) > 0
                 for k ∈ a
                     k ∉ exclude && (gd[k] = deepcopy(d[k]))
                 end
             else
                 for (k, v) ∈ pairs(d)
                     k ∉ exclude && (gd[k] = deepcopy(v))
                 end
             end
         else
             if length(a) > 0
                 for k ∈ a
                     k ∉ exclude && (gd[k] = d[k])
                 end
             else
                 for (k, v) ∈ pairs(ns.__dict)
                     k ∉ exclude && (gd[k] = v)
                 end
             end
         end
         g
     end)
_NSdict0[:deepimport] = ns ->
    ((g::AbstNS, a::Vararg{Symbol}; exclude=[]) ->
     ns.import(g, a...; exclude=exclude, deep=true))
_NSdict0[:deepexport] = ns ->
    ((a::Vararg{Symbol}; exclude=[]) -> ns.export(a...; exclude=exclude, deep=true))

# g.load("x.ns")
#     : load "x.ns" and import all properties from it
# g.load("x.ns", :a, :b, :c)
#     : load "x.ns" and import properties :a, :b, :c from it
_NSdict0[:load] = ns ->
    ((filename::AbstractString,
      atr::Vararg{Symbol};
      exclude=[],
      forcename=false) ->
     begin
         if !forcename &&
            (length(filename) < length("a.ns") ||
             filename[end-length(".ns")+1:end] != ".ns")
             filename = filename * ".ns"
         end
         ns.import(Serialization.deserialize(filename),
                   atr...;
                   exclude=exclude)
     end)
_NSdict0[:save] = ns ->
    ((filename::AbstractString,
      atr::Vararg{Symbol};
      exclude=[],
      forcename=false) ->
     begin
         if !forcename &&
            (length(filename) < length("a.ns") ||
             filename[end-length(".ns")+1:end] != ".ns")
             filename = filename * ".ns"
         end
         length(atr) == 0 && (atr = ns._keys)
         atr = [k for k ∈ ns._keys if k ∉ exclude]
         g = ns.copyout(atr...; exclude=exclude)
         Serialization.serialize(filename, g)
         g
     end)
_NSdict0[:haskey] = ns -> NShaskey(ns)
_NSdict0[:iscst] = ns ->
    (key -> (!haskey(ns.__dict, key) &&
             error("this NS does not have a key named '$(atr)'." );
             isa(ns.__dict[key], NScst_item)))
_NSdict0[:del] = ns -> NSdel(ns)
_NSdict0[:cstize] = ns -> NScstize(ns)
_NSdict0[:decstize] = ns -> NSdecstize(ns)

# tags
_NSdict0[:cst] = ns -> NScst(ns)
_NSdict0[:prp] = ns -> NSTag{:prp, false}(ns)
_NSdict0[:fnc] = ns -> NSTag{:fnc, false}(ns)
_NSdict0[:mth] = ns -> NSTag{:mth, false}(ns)
_NSdict0[:dfn] = ns -> NSTag{:dfn, false}(ns)
_NSdict0[:req] = ns -> NSTag{:req, false}(ns)

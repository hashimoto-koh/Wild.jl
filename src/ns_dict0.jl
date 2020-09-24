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
_NSdict0[:_vals] = ns -> Tuple(x.obj for x in Base.values(ns.__dict))
_NSdict0[:_keyvals] = ns -> (; zip(ns._keys, ns._vals)...)
_NSdict0[:_printkeyvals] =
    ns -> ([println(k, ": ", v) for (k,v) in pairs(ns._keyvals)]; return)
_NSdict0[:_printkeytypes] =
    ns -> ([println(k, ": ", typeof(v)) for (k,v) in pairs(ns._keyvals)]; return)
_NSdict0[:_fix] = ns -> (ns.__fix_lck[1] = true; ns)
_NSdict0[:_unfix] = ns -> (ns.__fix_lck[1] = false; ns)
_NSdict0[:_lck] = ns -> (ns.__fix_lck[2] = true;  ns)
_NSdict0[:_unlck] = ns -> (ns.__fix_lck[2] = false; ns)
_NSdict0[:_frz] = ns -> (ns.__fix_lck[1] = ns.__fix_lck[2] = true; ns)
_NSdict0[:_unfrz] = ns -> (ns.__fix_lck[1] = ns.__fix_lck[2] = false; ns)
_NSdict0[:_clr] = ns -> (ns.del(); ns)
_NSdict0[:_copy] = ns -> deepcopy(ns)
_NSdict0[:_cst_keys] =
    ns -> (d = ns.__dict; [k for k in Base.keys(d) if isa(d[k], NScst_item)])
_NSdict0[:_noncst_keys] =
    ns -> (d = ns.__dict; [k for k in Base.keys(d) if isa(d[k], NSnoncst_item)])
_NSdict0[:import] = ns ->
    ((g::AbstNS, a::Vararg{Symbol}; exclude=[], deep=false) ->
     begin
         d = ns.__dict
         gd = g.__dict
         if deep
             if length(a) > 0
                 for k in a
                     (k in exclude) || (d[k] = deepcopy(gd[k]))
                 end
             else
                 for (k, v) in pairs(gd)
                     (k in exclude) || (d[k] = deepcopy(v))
                 end
             end
         else
             if length(a) > 0
                 for k in a
                     (k in exclude) || (d[k] = gd[k])
                 end
             else
                 for (k, v) in pairs(gd)
                     (k in exclude) || (d[k] = v)
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
                 for k in a
                     if !(k in exclude)
                         x = deepcopy(d[k].obj)
                         gd[k] = (ns.iscst(k) ? NScst_item : NSnoncst_item)(x)
                     end
                 end
             else
                 for (k, w) in pairs(d)
                     if !(k in exclude)
                         x = deepcopy(w.obj)
                         gd[k] = (ns.iscst(k) ? NScst_item : NSnoncst_item)(x)
                     end
                 end
             end
         else
             if length(a) > 0
                 for k in a
                     if !(k in exclude)
                         v = d[k].obj
                         x = (isa(v, Fnc) ? Fnc(v.fnclist) : v)
                         gd[k] = (ns.iscst(k) ? NScst_item : NSnoncst_item)(x)
                     end
                 end
             else
                 for (k, w) in pairs(d)
                     if !(k in exclude)
                         v = w.obj
                         x = (isa(v, Fnc) ? Fnc(v.fnclist) : v)
                         gd[k] = (ns.iscst(k) ? NScst_item : NSnoncst_item)(x)
                     end
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
                 for k in a
                     if !(k in exclude)
                         x = deepcopy(gd[k].obj)
                         d[k] = (g.iscst(k) ? NScst_item : NSnoncst_item)(x)
                     end
                 end
             else
                 for (k, w) in pairs(gd)
                     if !(k in exclude)
                         x = deepcopy(w.obj)
                         d[k] = (g.iscst(k) ? NScst_item : NSnoncst_item)(x)
                     end
                 end
             end
         else
             if length(a) > 0
                 for k in a
                     if !(k in exclude)
                         v = gd[k].obj
                         x = (isa(v, Fnc) ? Fnc(v.fnclist) : v)
                         d[k] = (g.iscst(k) ? NScst_item : NSnoncst_item)(x)
                     end
                 end
             else
                 for (k, w) in pairs(gd)
                     if !(k in exclude)
                         v = w.obj
                         x = (isa(v, Fnc) ? Fnc(v.fnclist) : v)
                         d[k] = (g.iscst(k) ? NScst_item : NSnoncst_item)(x)
                     end
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
                 for k in a
                     (k in exclude) || (gd[k] = deepcopy(d[k]))
                 end
             else
                 for (k, v) in pairs(d)
                     (k in exclude) || (gd[k] = deepcopy(v))
                 end
             end
         else
             if length(a) > 0
                 for k in a
                     (k in exclude) || (gd[k] = d[k])
                 end
             else
                 for (k, v) in pairs(ns.__dict)
                     (k in exclude) || (gd[k] = v)
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

         _init_fnc(x::AbstNS) = begin
             for key in x._keys
                 if isa(x.__dict[key].obj, Fnc)
                     x.__dict[key].obj.init!
                 elseif isa(x.__dict[key].obj, AbstNS)
                     _init_fnc(x.__dict[key].obj)
                 end
             end
             x
         end
         ns.import(_init_fnc(Serialization.deserialize(filename)),
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
         atr = [k for k in ns._keys if !(k in exclude)]
         g = ns.copyout(atr...; exclude=exclude)

         _remove_fnc(x::AbstNS) = begin
             for key in x._keys
                 if isa(x.__dict[key].obj, Fnc)
                     x.__dict[key].obj.fnc = _FncWrapper(nothing)
                 elseif isa(x.__dict[key].obj, AbstNS)
                     _remove_fnc(x.__dict[key].obj)
                 end
             end
             x
         end
         Serialization.serialize(filename, _remove_fnc(g))
         g
     end)
_NSdict0[:haskey] = ns -> NShaskey(ns)
_NSdict0[:iscst] = ns ->
    (key -> (!haskey(ns.__dict, key) &&
             error("This NS does not have a key named $(atr)." );
             isa(ns.__dict[key], NScst_item)))
_NSdict0[:del] = ns -> NSdel(ns)
_NSdict0[:cstize] = ns -> NScstize(ns)
_NSdict0[:decstize] = ns -> NSdecstize(ns)

# tags
_NSdict0[:cst] = ns -> NScst(ns)
_NSdict0[:prp] = ns -> NSprp(ns)
_NSdict0[:fnc] = ns -> NSfnc(ns)
_NSdict0[:mth] = ns -> NSmth(ns)
_NSdict0[:dfn] = ns -> NSdfn(ns)
_NSdict0[:req] = ns -> NSreq(ns)

#=
const _NS_fields = Set([:_keys,
                        :_vals,
                        :_keyvals,
                        :_printkeyvals,
                        :_printkeytypes,
                        :_fixed,
                        :_lcked,
                        :_frzed,
                        :_fix,
                        :_unfix,
                        :_lck,
                        :_unlck,
                        :_frz,
                        :_unfrz,
                        :_cst_keys,
                        :_noncst_keys,
                        :_clr,
                        :_copy,
                        :copyout,
                        :copyfrom,
                        :import,
                        :export,
                        :deepimport,
                        :deepexport,
                        :load,
                        :save,
                        :haskey,
                        :iscst,
                        :del,
                        :cstize,
                        :decstize,
                        :cst,
                        :dfn,
                        :req,
                        :prp,
                        :mth,
                        :fnc,
                        :exe
                        ])
=#
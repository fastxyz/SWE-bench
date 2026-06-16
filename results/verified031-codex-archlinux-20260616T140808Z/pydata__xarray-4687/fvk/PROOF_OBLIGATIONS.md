# Proof Obligations

Status: constructed, not machine-checked.

| ID | Obligation | Evidence | Status |
|---|---|---|---|
| PO-1 | Preserve value semantics: output values are `duck_array_ops.where(cond, x, y)`. | E8, claim WHERE-VALUE | Discharged by helper body |
| PO-2 | Preserve exact alignment policy. | Existing source contract, claim WHERE-EXACT-JOIN | Discharged by unchanged `join`/`dataset_join` kwargs |
| PO-3 | `keep_attrs=True` preserves attrs from data arguments before mask attrs. | E2, E3, E7, claim WHERE-KEEP-TRUE | Discharged by `apply_ufunc` argument order `x, y, cond` |
| PO-4 | `keep_attrs=False` drops attrs. | E6, claim WHERE-KEEP-FALSE | Discharged by `apply_ufunc` bool-to-`"drop"` behavior |
| PO-5 | `keep_attrs=None` respects global option with operation default true. | E2, E6, E7, claim WHERE-KEEP-NONE | Discharged by `_get_keep_attrs(default=True)` |
| PO-6 | Existing three-argument callsites remain valid. | E9, compatibility audit | Discharged by optional parameter |
| PO-7 | Do not claim to fix attrs already removed from a comparison when `x` and `y` are scalars. | E4, FVK-F1 | Recorded limitation |
| PO-8 | Do not change dtype promotion. | E10 | Discharged by leaving `duck_array_ops.where` unchanged |

No loop or recursive circularity obligations apply to the changed code.

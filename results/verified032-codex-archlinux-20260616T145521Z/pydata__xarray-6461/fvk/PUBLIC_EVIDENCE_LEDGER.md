# Public Evidence Ledger

| ID | Source | Evidence | Semantic obligation | Status |
|---|---|---|---|---|
| E1 | prompt issue | "`xr.where` with scalar as second argument fails with `keep_attrs=True`" | Scalar `x` is in-domain for `xr.where` with attrs preservation enabled. | Encoded in SPEC and claims. |
| E2 | prompt issue | Traceback points to `keep_attrs = lambda attrs, context: attrs[1]` and `IndexError: list index out of range`. | The bug is a positional attr-list assumption, not numeric `where` computation. | Encoded as finding F1 and PO1. |
| E3 | prompt issue | "The workaround is to pass `keep_attrs=False`." | `keep_attrs=True` should work without requiring users to disable attrs handling. | Encoded in PO1. |
| E4 | `where` docstring | "`keep_attrs`: How to treat attrs. If True, keep the attrs of `x`." | Attr source is `x`, the second parameter. | Encoded in PO2 and PO3. |
| E5 | `where` docstring | "`x`: scalar, array, Variable, DataArray or Dataset." | Scalar `x` is a valid public input class. | Encoded in PO1 and PO2. |
| E6 | implementation fact | `apply_ufunc` gathers attrs only from xarray-like objects before calling `merge_attrs`. | A raw scalar contributes no attrs entry, so the `where` adapter must not assume fixed position `1`. | Encoded in K model and finding F1. |
| E7 | compatibility audit | Public signature remains `where(cond, x, y, keep_attrs=None)`. | No callsite migration or override update is required. | Encoded in PO5 and compatibility audit. |

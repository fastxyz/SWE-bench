# Public Evidence Ledger

| ID | Source | Evidence | Semantic Obligation | Status |
|---|---|---|---|---|
| E1 | prompt/issue | "`xr.where` not preserving attributes" | Attr loss in top-level `xr.where` is the defect to repair. | Encoded |
| E2 | prompt/issue | "Attributes should be preserved or at least there should be a choice" | Provide preservation, or at minimum a public control for preservation. | Encoded by `keep_attrs` |
| E3 | prompt/issue | `xr.where(da==0, -1, da).attrs` expected `{'foo': 'bar'}` | Attrs from `da` in `y` should be considered when preserving attrs. | Encoded by data-first attr order |
| E4 | public hint | "`DataArray.__eq__` removes the attributes ... without `xr.set_options(keep_attrs=True)` `data == 1` won't keep the attributes" | Already-dropped comparison attrs are a separate limitation from `xr.where`. | Finding FVK-F1 |
| E5 | public hint | "`xr.where` does not pass `keep_attrs` to `apply_ufunc`" | The root cause is the missing `keep_attrs` propagation in top-level `where`. | Encoded |
| E6 | public hint | "simply adding `keep_attrs=True` seems like a breaking change. Do we need to add a `keep_attrs` kwarg or get the value from `OPTIONS['keep_attrs']`?" | Add a public parameter and respect global option rather than hard-coding only one behavior. | Encoded; compatibility finding FVK-F2 |
| E7 | public hint | Workaround `da.where(da == 0, -1).attrs -> {'foo': 'bar'}` | Method-level `where` preserves attrs from data object; top-level behavior should be compatible with that expectation. | Encoded |
| E8 | source/docstring | `where` returns elements from `x` or `y` depending on `cond` | Value semantics must not change while metadata handling changes. | Encoded by PO-1 |
| E9 | source/tests | Existing public tests call `xr.where` with three positional arguments. | Adding `keep_attrs` must not break existing calls. | Encoded by compatibility audit |
| E10 | prompt/issue | dtype note says dtype may be a numpy issue | Do not broaden the targeted fix into dtype promotion. | Out of scope |

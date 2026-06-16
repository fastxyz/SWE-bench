# Public Evidence Ledger

Status: constructed for FVK audit; not machine-checked.

| ID | Source | Evidence | Semantic obligation | Status |
| --- | --- | --- | --- | --- |
| E-1 | Problem title | "`center` kwarg ignored when manually iterating over DataArrayRolling" | `center` is part of iterator behavior, not only reduction behavior. | Encoded by PO-3/PO-4. |
| E-2 | Problem text | "manually iterate over a DataArrayRolling object, and still be given center-justified windows" | Manual iteration with `center=True` must yield centered logical windows. | Encoded by PO-3/PO-4. |
| E-3 | Problem example | Centered reduction returns `[nan, 2, 3, 4, 5, 6, 7, 8, nan]`; manual V0 returns `[nan, nan, 2, 3, 4, 5, 6, 7, 8]`. | The right-aligned manual sequence is the bug, not an expected behavior. | FI-1; concrete claims in `rolling-iter-spec.k`. |
| E-4 | `DataArray.rolling` docstring | "Set the labels at the center of the window." | `center=True` changes window alignment while preserving coordinates. | Encoded by IS-1/IS-3. |
| E-5 | User guide | "Aggregation results are assigned the coordinate at the end of each window by default, but can be centered by passing `center=True`" and "We can also manually iterate through `Rolling` objects" | Manual iteration should be compatible with the documented alignment of the `Rolling` object. | Encoded by PO-2/PO-3. |
| E-6 | `Variable.rolling_window` docs/code | Centered rolling pads `start = win // 2`, `end = win - 1 - start`. | The authoritative centered bounds are `start=max(I-W//2,0)`, `stop=min(I+(W-1)//2+1,N)`. | Encoded by PO-3 and K claim. |
| E-7 | Public `test_rolling_iter` | Iterator mean equals rolling mean for default right-aligned rolling. | Preserve right-aligned iterator behavior. | Encoded by PO-2. |
| E-8 | Public construct tests | `construct` is compared for `center` in `(True, False)` and `window` in `(1,2,3,4)`. | Even window sizes must follow existing construction semantics, not an ad hoc odd-only rule. | Encoded by PO-4. |
| E-9 | `Rolling.__init__` | `window must be > 0`; `min_periods` must be positive or `None`. | Formal domain can assume `W > 0`; masking is a frame condition for this audit. | Encoded by PO-1/PO-7. |

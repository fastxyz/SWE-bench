# Public Evidence Ledger

Status: constructed for FVK audit, not machine-checked.

| ID | Source | Evidence | Semantic obligation | Status |
| --- | --- | --- | --- | --- |
| E1 | `benchmark/PROBLEM.md` | "merge(combine_attrs='override') does not copy attrs but instead references attrs from the first object" | The bug is object aliasing in override attrs, not the selected contents. | Encoded in PO1, PO2, K claim `MERGE-ATTRS-OVERRIDE-COPY`. |
| E2 | `benchmark/PROBLEM.md` | "After a merge, the attrs of the merged product should be able to be changed without having any effect on the sources." | Result attrs and source attrs must be independent mutable mappings. | Encoded in PO1, PO2, PO3. |
| E3 | `benchmark/PROBLEM.md` | Example expects `a3` initially equal to first source value `b`, then result mutation to `d` must leave `a1` as `b`. | Override result contents equal first attrs initially; mutation frame condition protects source attrs. | Encoded in PO1, PO3. |
| E4 | `benchmark/PROBLEM.md` | Reporter suggests `return dict(variable_attrs[0])`, "like it is for the other combine_attrs cases." | A shallow `dict(...)` copy is sufficient for the reported mapping-alias defect and consistent with sibling modes. | Encoded in PO2, PO5. |
| E5 | `repo/xarray/core/merge.py` docstring | `override`: "copy attrs from the first dataset to the result." | "copy" supports fresh result mapping with first-input contents. | Encoded in PO1, PO2. |
| E6 | `repo/xarray/core/concat.py` docstring | `override`: "copy attrs from the first dataset to the result." | Shared helper behavior should be copy-like for concat callers too. | Encoded in PO4 compatibility. |
| E7 | `repo/xarray/core/merge.py` implementation | `merge_core` passes helper attrs into `_MergeResult`; `merge` then calls `Dataset._construct_direct`. | The helper must return a fresh mapping because the fast-path constructor stores attrs directly. | Implementation evidence for PO3. |
| E8 | `repo/xarray/core/dataset.py` implementation | `Dataset._construct_direct` assigns `obj._attrs = attrs`; `Dataset.attrs` setter uses `dict(value)`. | Fast-path construction does not repair aliasing; ordinary setter paths copy. | Implementation evidence for PO3 and PO4. |
| E9 | V1 source | `override` branch now returns `dict(variable_attrs[0])`. | Candidate behavior satisfies shallow-copy content and non-alias obligations. | Confirmed by proof sketch; no V2 source edit required. |

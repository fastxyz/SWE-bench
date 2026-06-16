# Public Evidence Ledger

| ID | Source | Evidence | Semantic obligation | Status |
|---|---|---|---|---|
| E-001 | issue | "`.swap_dims()` can modify original object" | This is the reported bug: mutation of the input object is forbidden. | Encoded by I-004, PO-001, PO-002. |
| E-002 | issue | "I expected it not to modify the original object." | Strong frame condition over the input dataset and its stored variable metadata. | Encoded by I-004 and the no-alias proof. |
| E-003 | issue MVCE | "`ds2['lev']` now has dimension 'lev' although otherwise same" | Concrete failing family member: replacement variable `lev` is already an `IndexVariable`-like object and is promoted to a dimension coordinate. | Encoded by PO-002 and FINDING F-001. |
| E-004 | docstring | "`Dataset.swap_dims`: Returns a new object with swapped dimensions." | The method's public contract is returning a transformed object, not mutating the input object. | Encoded by I-001 and I-004. |
| E-005 | docstring/examples | Examples show dimension metadata rewritten in the returned dataset. | Returned variable dimensions must be rewritten according to `dims_dict`. | Encoded by I-002 and PO-003. |
| E-006 | implementation validation | Existing checks reject missing source dimensions and invalid replacement variables. | These validation branches are public behavior to preserve because the issue does not ask to change them. | Encoded by I-005 and PO-005. |
| E-007 | implementation fact | `IndexVariable.to_index_variable()` returns `self`. | This is not intent, but it identifies the aliasing mechanism that must be neutralized before assigning `.dims`. | Encoded by PO-002 and FINDING F-002. |
| E-008 | implementation fact | `Variable.to_base_variable()` constructs a new base `Variable`. | The non-promoted branch already owns a distinct object before assigning `.dims`. | Encoded by PO-004. |
| E-009 | implementation fact | `IndexVariable.copy(deep=False)` returns `_replace(data=self._data.copy(deep=False))`. | The V1 copy creates a distinct metadata object while retaining shallow data behavior. | Encoded by PO-002 and PO-006. |

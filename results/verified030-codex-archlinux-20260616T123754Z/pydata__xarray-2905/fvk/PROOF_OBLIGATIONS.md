# Proof Obligations

Status: constructed, not machine-checked.

| ID | Obligation | Evidence | Formal claim(s) | Status |
| --- | --- | --- | --- | --- |
| PO1 | `as_compatible_data` must preserve arbitrary non-container objects with `.values` as object data, not unwrap their payload. | E1-E7, E9 | `ARBITRARY-VALUES-PRESERVED` | Discharged by V1 source inspection and constructed proof. |
| PO2 | Scalar `Variable.__setitem__` assignment must preserve the arbitrary object after helper conversion. | E1-E5, E14 | `SCALAR-SETITEM-PRESERVES-ARBITRARY-VALUES-OBJECT` | Discharged. `__setitem__` delegates to `as_compatible_data`; V1 helper preserves the object. |
| PO3 | Scalar `DataArray(..., dims=[])` construction must preserve the arbitrary object after helper conversion. | E8-E9, E15 | `SCALAR-DATAARRAY-CONSTRUCT-PRESERVES-ARBITRARY-VALUES-OBJECT` | Discharged. Construction delegates to `as_compatible_data`; V1 helper preserves the object. |
| PO4 | Known pandas/xarray containers that are meant to provide array values remain unwrapped. | E9-E13 | `KNOWN-CONTAINER-UNWRAPS-VALUES` | Discharged. V1 explicitly unwraps `Series`, `DataFrame`, `pdcompat.Panel`, and `DataArray`; `Variable` has an earlier branch. |
| PO5 | Existing `Variable`, `pandas.Index`, supported non-NumPy array, and adapter branches are unchanged. | E10-E13 | `VARIABLE-AND-ADAPTER-FRAME`, `NON-NUMPY-SUPPORTED-FRAME` | Discharged. The V1 edit occurs after the existing early branches. |
| PO6 | Datetime, timedelta, masked-array, NEP-18, object-array conversion, and shape/broadcast checks remain unchanged except for the intended `.values` dispatch. | I6, implementation inspection | Covered as frame reasoning in `PROOF.md` | Discharged by source inspection; no edited code in those branches. |
| PO7 | Public compatibility: no method signature, virtual dispatch shape, or public return protocol changes beyond the intended object preservation. | I7, `PUBLIC_COMPATIBILITY_AUDIT.md` | Compatibility audit | Discharged. |
| PO8 | Honesty gate: proof/test conclusions must be labeled constructed, not machine-checked; no tests may be removed or edited. | FVK docs, task constraints | `PROOF.md` commands and F4/F5 | Discharged by artifact labeling and no test edits. |

## Obligations Considered and Rejected

R1. Add `pd.Index` to the explicit `.values` tuple. Rejected for this codebase:
`pd.Index` is already handled earlier by `NON_NUMPY_SUPPORTED_ARRAY_TYPES` and
`_maybe_wrap_data`, and public tests cover adapter preservation. Moving it into
the later `.values` branch would be an unrelated behavior change.

R2. Special-case only `Variable.__setitem__`. Rejected because E8 shows the same
bug in scalar construction, and both paths share `as_compatible_data`.

R3. Keep a generic `.values` fallback with scalar heuristics. Rejected because
E7-E9 call for explicit type checking and because it would preserve the same
ambiguity that caused F1/F2.

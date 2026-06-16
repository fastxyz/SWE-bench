# Proof Obligations

Status: constructed, not machine-checked.

| ID | Obligation | Evidence | Disposition |
| --- | --- | --- | --- |
| PO-001 | Valid boolean `X` is in the `HuberRegressor.fit` input domain for this bug. | E-001, E-002 | Discharged by intent. |
| PO-002 | `fit` must convert boolean `X` to a floating dtype before optimizer/loss evaluation. | E-003, E-005 | Discharged by V1 `dtype=FLOAT_DTYPES`; non-float dtypes are cast to `np.float64`. |
| PO-003 | Once `X` is floating point, `_huber_loss_and_gradient` cannot raise the reported boolean-unary-minus TypeError at `-axis0_safe_slice(...)`. | E-007 | Discharged by C-001/C-002: `gradientSquared` receives only a float dtype on the V1 path. |
| PO-004 | Already-floating `X` must remain on the previously working path. | E-004, E-005 | Discharged by `check_array` dtype-list behavior: `float64`, `float32`, and `float16` are preserved. |
| PO-005 | Public API and unrelated validation behavior must be preserved. | E-008 | Discharged by source diff: signature, sparse policy, target validation, sample-weight handling, parameter checks, and optimizer call shape are unchanged. |
| PO-006 | Accepted CSR sparse boolean `X` must receive the same dtype safety as dense boolean `X`. | E-006 | Discharged by sparse validation casting through `_ensure_sparse_format(..., dtype=FLOAT_DTYPES, ...)`; modeled generically by storage `S:Storage`. |
| PO-007 | Direct boolean calls to `_huber_loss_and_gradient` do not block confirmation of V1. | Public issue names `HuberRegressor.fit`; helper is private. | Discharged as a scope/precondition boundary: helper `X` is assumed to come from public `fit` validation. |
| PO-008 | The proof must not claim full Huber numerical correctness. | FVK adequacy boundary | Discharged by explicit scope limit in `SPEC.md` and `PROOF.md`; numerical tests remain necessary. |

No proof obligation requires a source edit beyond V1.

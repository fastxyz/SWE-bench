# FVK Proof Obligations

Status: constructed, not machine-checked. These obligations were reasoned
about statically; no proof tool was run.

| ID | Obligation | Evidence | Status |
| --- | --- | --- | --- |
| PO1 | `_validate_size` must reject negative, zero, non-integral values above 1, and sizes greater than `n_samples` before normalization. | Source lines 280-290; public docs define positive integer or float fraction. | Assumed as existing precondition guard for this proof. |
| PO2 | In `compute_optics_graph`, if validated `min_samples <= 1`, the normalized count is exactly `int(round(max(2, min_samples * n_samples)))`. | IE2, IE4, IE8; F1. | Discharged by V2 source expression. |
| PO3 | For fractional `min_samples`, `NearestNeighbors(n_neighbors=...)` receives an integer count, avoiding the issue traceback. | IE3; F2; neighbor validation requires `numbers.Integral`. | Discharged by PO2 plus `int(...)`. |
| PO4 | In `cluster_optics_xi`, fractional `min_samples` and `min_cluster_size` use the same rounded integer count conversion. | IE6; F3. | Discharged by V2 source expressions. |
| PO5 | If `min_cluster_size is None`, Xi uses the already-normalized `min_samples`, not the original fractional value. | Source order in `cluster_optics_xi`; F3. | Discharged by assignment after min-samples normalization. |
| PO6 | `compute_optics_graph` documentation must state that `min_samples` may be a float fraction. | IE7. | Discharged by the docstring update. |
| PO7 | Exact Python float rounding and ties must match Python runtime behavior. | F4. | Escalation boundary; code delegates to built-ins, but mini-K does not fully model floats. |
| PO8 | Do not edit tests or changelog under benchmark constraints. | User constraints; F5. | Discharged by leaving tests and changelog untouched. |
| PO9 | Full OPTICS reachability ordering and clustering labels remain behaviorally framed by this patch. | Source diff only changes size normalization and one docstring. | Not formally proved; treated as unchanged frame behavior. |

## Machine-Check Commands Not Run

The commands that would check the formal core in an environment with K are:

```sh
kompile fvk/mini-optics-size.k --backend haskell
kast --backend haskell fvk/optics-size-spec.k
kprove fvk/optics-size-spec.k
```

Expected constructed result: `#Top` for the abstraction claims in
`optics-size-spec.k`, subject to the proof boundary in PO7.

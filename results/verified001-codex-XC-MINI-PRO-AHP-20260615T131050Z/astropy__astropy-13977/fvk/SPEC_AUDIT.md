# Spec Audit

Status: pass, with explicit scope boundaries.

| Formal claim | Intent entries | Result | Notes |
| --- | --- | --- | --- |
| C1 | Intent 1, 2, 6 | pass | Captures return of `NotImplemented` for unknown unit-bearing objects in inputs or outputs. |
| C2 | Intent 4, 5 | pass | Preserves existing path for recognized and non-unit objects. |
| C3 | Intent 2, 3 | pass | Captures the reported failure cause: converter application must not happen. |
| C4 | Intent 4 | pass | Column compatibility is represented through ndarray subclass acceptance. |

Scope boundary: the claims do not specify full NumPy dispatch or all unit
conversion behavior after `PROCEED`. That is acceptable for this issue because
the public defect occurs before that path.


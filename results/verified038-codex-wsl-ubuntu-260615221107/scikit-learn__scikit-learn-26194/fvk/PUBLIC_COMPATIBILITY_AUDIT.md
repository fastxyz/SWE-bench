# Public Compatibility Audit

Status: constructed, not machine-checked.

CA1. Public symbol: `sklearn.metrics.roc_curve`. Signature unchanged.

CA2. Return shape: unchanged in structure. `fps`, `tps`, and `thresholds` each
receive one prepended element.

CA3. Comparison semantics: preserved. For finite validated scores,
`score >= np.inf` is false, matching the artificial no-prediction threshold
intent.

CA4. Dtype compatibility: integer threshold arrays may promote to a floating
dtype to hold `np.inf`. This is an acceptable consequence of representing an
explicit non-finite sentinel and is not contradicted by public intent.

CA5. Public tests: tests expecting no NaN remain compatible with `np.inf`.
Exact tests expecting finite `2.0` are SUSPECT legacy tests under E6 and were
not modified by this task.

CA6. Documentation: public examples changed in V1 to display `inf`, aligning
docs with the new behavior.

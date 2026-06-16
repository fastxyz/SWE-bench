# FVK Notes

## Decision

V1 stands unchanged. The FVK audit did not surface a source-code problem that
would justify a V2 edit.

## Trace To Findings And Proof Obligations

Finding F-001 identifies the original bug: `sympify(2.0) * Point(1, 1)` was
constructed as a symbolic `Mul`, which later made point addition fail. PO1,
PO2, PO3, and PO4 discharge that bug: `Point.__rmul__` delegates to the
existing coordinate-scaling `Point.__mul__`, and `_op_priority = 10.001` lets
ordinary SymPy scalar-left multiplication reach that method. This supports
keeping the V1 `__rmul__` and `_op_priority` changes.

Finding F-002 identifies the main compatibility risk introduced by adding
priority to `Point`: inherited `GeometryEntity` reflected add/sub/div methods
would delegate back to ordinary `Expr` operations. PO5 discharges that risk by
requiring `Expr + Point`, `Expr - Point`, and `Expr / Point` to preserve their
symbolic construction forms. This supports keeping V1's `__radd__`,
`__rsub__`, `__rdiv__`, and `__rtruediv__` shims.

Finding F-003 checks whether the selected priority is too broad. PO6 discharges
the concern: the value is above ordinary `Expr` priority, which is necessary
for the issue's `sympify(2.0)` path, and not above higher-priority systems
found in the static non-test source scan. This supports keeping the numeric
priority value rather than increasing it or moving the fix into SymPy core.

PO7 confirms the fix remains point-specific, does not alter `GeometryEntity`,
does not require subclass signature changes, and does not touch tests. This
supports making no additional source edits.

## Artifacts Written

The requested FVK artifacts are:

- `fvk/SPEC.md`
- `fvk/FINDINGS.md`
- `fvk/PROOF_OBLIGATIONS.md`
- `fvk/PROOF.md`
- `fvk/ITERATION_GUIDANCE.md`

The FVK adequacy and formal-core support artifacts are:

- `fvk/INTENT_SPEC.md`
- `fvk/PUBLIC_EVIDENCE_LEDGER.md`
- `fvk/FORMAL_SPEC_ENGLISH.md`
- `fvk/SPEC_AUDIT.md`
- `fvk/PUBLIC_COMPATIBILITY_AUDIT.md`
- `fvk/mini-python-point.k`
- `fvk/point-scalar-spec.k`

## Execution Policy

No tests, Python code, or K tooling were run. The proof is labeled
"constructed, not machine-checked" throughout the artifacts, as required by the
FVK honesty gate and the benchmark instructions.

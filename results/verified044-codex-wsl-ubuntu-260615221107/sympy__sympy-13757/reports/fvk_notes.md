# FVK Notes

## Decision

V1 stands unchanged. No additional production-code edits were made after the FVK audit.

## Trace to findings and proof obligations

- F-1 shows the reported pre-V1 failures, `x*Poly(x)` and `S(-2)*Poly(x)`, are caused by right-hand `Poly` not being selected by SymPy's priority dispatch. PO-2 proves the V1 side condition needed for dispatch, `Poly._op_priority > Expr._op_priority`, and PO-3 shows that once dispatch reaches `Poly.__rmul__`, the existing conversion and polynomial multiplication logic handles both examples. This justifies keeping the V1 source edit in `repo/sympy/polys/polytools.py`.

- F-2 records the main audit concern: `_op_priority` is class-level, so V1 can affect reflected `Poly` arithmetic beyond multiplication. PO-4 shows incompatible operands still use the existing expression fallback, and PO-5 shows the chosen value `10.001` is narrowly above ordinary `Expr` while remaining below higher matrix-like dispatch priorities. This is why I did not replace V1 with a core `Expr.__mul__` special case.

- F-3 and PO-6 require the honesty caveat: the proof artifacts are constructed but not machine-checked. I did not run tests, Python, `kompile`, `kast`, or `kprove`, and I did not modify test files.

## Artifacts produced

The requested FVK artifacts are:

- `fvk/SPEC.md`
- `fvk/FINDINGS.md`
- `fvk/PROOF_OBLIGATIONS.md`
- `fvk/PROOF.md`
- `fvk/ITERATION_GUIDANCE.md`

The additional FVK adequacy and formal-core artifacts required by the FVK docs are:

- `fvk/INTENT_SPEC.md`
- `fvk/PUBLIC_EVIDENCE_LEDGER.md`
- `fvk/FORMAL_SPEC_ENGLISH.md`
- `fvk/SPEC_AUDIT.md`
- `fvk/PUBLIC_COMPATIBILITY_AUDIT.md`
- `fvk/mini-sympy-dispatch.k`
- `fvk/poly-dispatch-spec.k`

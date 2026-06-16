# FVK Notes

## Decision

V1 stands unchanged. No source files were edited during the FVK pass.

## Trace to findings and proof obligations

- `fvk/FINDINGS.md` F1 identifies the pre-V1 product-over-addition rule as the
  root bug. `fvk/PROOF_OBLIGATIONS.md` PO1 is the constructed obligation showing
  the V1 additive branch returns `None` when denominator clearing leaves a
  numeric denominator product, so the invalid sum-of-products fallback is no
  longer reachable.

- `fvk/FINDINGS.md` F2 covers the reported
  `Product(n + 2**(-k), (k, 0, n - 1))` path. PO2 and PO5 show that the outer
  denominator-clearing path now declines evaluation when the cleared numerator
  is still an unevaluable addition; PO4 then maps `None` to the documented
  unevaluated `Product` fallback.

- `fvk/FINDINGS.md` F3 records the main compatibility risk: disabling valid
  rational products. PO3 keeps the successful quotient path when both the
  numerator product and a nonnumeric denominator product are available, so the
  V1 change is narrow enough to preserve that behavior.

- `fvk/FINDINGS.md` F4 explains why I did not add a q-Pochhammer closed form.
  The prompt names q-Pochhammer as the mathematical form, but this checkout has
  no q-Pochhammer primitive and the public `Product` contract allows an
  unevaluated fallback. PO4 is the proof obligation that makes this fallback an
  intentional result rather than an unhandled regression.

- `fvk/FINDINGS.md` F5 records the honesty caveat: the proof is constructed but
  not machine-checked because the task forbids running K tooling, Python, or
  tests. The exact future commands are in `fvk/PROOF.md`.

## Artifacts written

The requested artifacts are:

- `fvk/SPEC.md`
- `fvk/FINDINGS.md`
- `fvk/PROOF_OBLIGATIONS.md`
- `fvk/PROOF.md`
- `fvk/ITERATION_GUIDANCE.md`

I also wrote the FVK adequacy and formal-core files required by the kit:

- `fvk/INTENT_SPEC.md`
- `fvk/PUBLIC_EVIDENCE_LEDGER.md`
- `fvk/FORMAL_SPEC_ENGLISH.md`
- `fvk/SPEC_AUDIT.md`
- `fvk/PUBLIC_COMPATIBILITY_AUDIT.md`
- `fvk/mini-sympy-product.k`
- `fvk/product-add-spec.k`

No tests or project code were run.

# FVK Notes

Status: constructed, not machine-checked. No tests, Python, or K tooling were
run.

## Decision

V1 stands unchanged after the FVK audit.

## Trace to Findings and Proof Obligations

F-001 identifies the original `tensor_product_simp` bug: a `Pow` over a
`TensorProduct` kept the exponent outside the tensor product, preventing
component simplification. PO-001 proves the component-wise helper, and PO-002
proves `tensor_product_simp_Pow` reaches it when the simplified base is a
`TensorProduct`. This supports keeping the V1 changes in
`repo/sympy/physics/quantum/tensorproduct.py`.

F-002 identifies the matching `expand(tensorproduct=True)` bug: a `Pow` node
had no tensor-product expansion dispatch point. PO-004 proves the V1
`Pow._eval_expand_tensorproduct` hook delegates only when the base advertises
`_eval_expand_tensorproduct_pow`. This supports keeping the V1 change in
`repo/sympy/core/power.py`.

F-003 records the decision not to add `TensorProduct._eval_power`. PO-007 ties
that non-change to the public issue and hint, which require the explicit
`tensor_product_simp` and `expand(tensorproduct=True)` paths rather than
automatic construction-path evaluation. No source edit is justified for this
point.

F-004 audits the public compatibility risk of adding a core `Pow` hook. PO-004
shows the hook returns `self` for bases without `_eval_expand_tensorproduct_pow`,
so non-tensor powers preserve existing behavior under the tensor-product hint.
No additional compatibility edit is justified.

F-005 records the proof-process limitation: the FVK proof is constructed, not
machine-checked. PO-008 lists the commands that would need to be run in a K
environment. This justifies leaving tests untouched and avoiding any claim that
the proof has been machine-verified.

## Artifacts Produced

The FVK phase produced:

- `fvk/SPEC.md`
- `fvk/FINDINGS.md`
- `fvk/PROOF_OBLIGATIONS.md`
- `fvk/PROOF.md`
- `fvk/ITERATION_GUIDANCE.md`

No production source files were edited during this FVK phase.

# FVK Notes

## Decision

V1 stands unchanged. The FVK audit did not justify a source-code edit beyond the
existing V1 changes in `dagger.py` and `operator.py`.

## Trace to Findings and Proof Obligations

`repo/sympy/physics/quantum/dagger.py`

- Decision: keep the V1 `Dagger.__mul__` special case.
- Reason: `fvk/FINDINGS.md` F1 identifies the reported bug as
  `Dagger(Operator) * IdentityOperator()` retaining the identity factor.
  `fvk/PROOF_OBLIGATIONS.md` PO-DAGGER-RIGHT-ID states the required postcondition:
  return `Dagger(Operator)`. The V1 branch matches exactly that discriminator:
  right operand is `IdentityOperator`, and the dagger wraps an `Operator`.
- Frame decision: keep fallback delegation to `Expr.__mul__`.
- Reason: F3, PO-DAGGER-NONOP-FRAME, and PO-NONOP-FRAME require non-operator
  operands to remain generic multiplication rather than being erased by the
  quantum identity.

`repo/sympy/physics/quantum/operator.py`

- Decision: keep the V1 extension to `IdentityOperator.__mul__`.
- Reason: F2 and PO-DAGGER-LEFT-ID derive the symmetric left-identity case from
  the `IdentityOperator` docstring: `IdentityOperator() * Dagger(Operator)` must
  return `Dagger(Operator)`.
- Frame decision: keep the existing `Operator` branch and generic `Mul` fallback.
- Reason: PO-OP-LEFT-ID preserves the established `IdentityOperator() * Operator`
  behavior, while PO-NONOP-FRAME preserves public behavior such as
  `IdentityOperator() * x` producing a generic `Mul`.

## Rejected Alternatives

- I did not move the fix into core `Mul` simplification. F3 and PO-NONOP-FRAME
  make the non-operator frame explicit, and the public tests show that some
  identity products intentionally remain `Mul`.
- I did not broaden the contract to arbitrary composite operator expressions.
  `fvk/INTENT_SPEC.md` fixes the audited domain to direct binary multiplication,
  matching the issue example and existing method-based behavior.
- I did not modify tests or run tests, Python, `kompile`, or `kprove`, as the task
  forbids execution and test edits. The proof is therefore labeled constructed,
  not machine-checked.

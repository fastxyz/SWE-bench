# Findings

Status: constructed, not machine-checked.

## F1: Reported right-identity failure is fixed by V1

- Classification: code bug, resolved by V1.
- Input: `Dagger(Operator('A')) * IdentityOperator()`.
- Observed before V1: generic multiplication retained the identity factor,
  shown in the issue as `A^\dagger I`.
- Expected: `Dagger(Operator('A'))`.
- Evidence: E1, E2; proof obligation PO-DAGGER-RIGHT-ID.
- V1 status: `Dagger.__mul__` returns `self` exactly when the right operand is
  `IdentityOperator` and the dagger wraps an `Operator`.

## F2: Symmetric left-identity gap is covered by V1

- Classification: code bug implied by public docstring, resolved by V1.
- Input: `IdentityOperator() * Dagger(Operator('A'))`.
- Observed before V1: `IdentityOperator.__mul__` only recognized `Operator`
  instances, and `Dagger(Operator)` is an unevaluated `Dagger` expression.
- Expected: `Dagger(Operator('A'))`.
- Evidence: E3; proof obligation PO-DAGGER-LEFT-ID.
- V1 status: `IdentityOperator.__mul__` now treats `Dagger(Operator)` as an
  operator-valued target.

## F3: Non-operator multiplication frame is preserved

- Classification: compatibility frame, confirmed by proof obligations.
- Input: `IdentityOperator() * x` where `x` is not an operator-valued target.
- Expected: generic `Mul`, not identity erasure.
- Evidence: E5; proof obligations PO-DAGGER-NONOP-FRAME and PO-NONOP-FRAME.
- V1 status: both modified methods retain generic multiplication fallback for
  non-operator operands.

## Proof-Derived Findings

No proof-derived code defect was found. The constructed proof obligations cover
the full direct-operation intent from the issue and docstring while preserving
the public non-operator frame behavior.

## Open / Not Machine-Checked

The K-style proof has not been run through `kompile` or `kprove`, per task
instructions. The expected machine-check result for `fvk/identity-dagger-spec.k`
is `#Top` after running the commands listed in `fvk/PROOF.md`.

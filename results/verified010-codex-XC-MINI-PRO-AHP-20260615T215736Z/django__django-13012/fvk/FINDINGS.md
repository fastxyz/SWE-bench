# FVK Findings

Status: constructed, not machine-checked. Findings are based on public intent,
source inspection, and proof-obligation construction only.

## F-001: V1 addressed the reported constant-wrapper bug

- Classification: code bug in the pre-fix implementation, addressed by V1 and
  retained in V2.
- Evidence: E-001, E-002, E-004, E-007.
- Input: `ExpressionWrapper(Value(3), output_field=IntegerField()).get_group_by_cols(alias=None)`.
- Pre-fix observed behavior: inherited `BaseExpression.get_group_by_cols()` for
  a non-aggregate expression, returning `[self]`.
- Expected behavior: `[]`, matching `Value.get_group_by_cols()`.
- Proof obligations: PO-001, PO-003.
- Status: discharged by adding `ExpressionWrapper.get_group_by_cols()` and
  delegating to the wrapped expression.

## F-002: V1 introduced a nested legacy-signature compatibility risk

- Classification: code bug in V1, addressed in V2.
- Evidence: E-003, E-005, E-006.
- Input: `ExpressionWrapper(MissingAliasFunc(), output_field=...)` where
  `MissingAliasFunc.get_group_by_cols(self)` omits `alias`.
- V1 observed behavior by inspection: `ExpressionWrapper.get_group_by_cols()`
  always called `self.expression.get_group_by_cols(alias=alias)`, which would
  pass an unsupported keyword to a legacy child override.
- Expected behavior: emit `RemovedInDjango40Warning` with the existing message
  shape and call the child method without `alias`, matching Django 3.2's public
  deprecation path for annotations.
- Proof obligations: PO-004, PO-005.
- Status: discharged in V2 by inspecting the child method signature before
  forwarding `alias`.

## F-003: No evidence supports changing `BaseExpression` or `Value`

- Classification: rejected alternative.
- Evidence: E-001, E-004, E-007.
- Input: any direct `Value(...)` expression.
- Observed behavior: `Value.get_group_by_cols()` already returns `[]`.
- Expected behavior: unchanged direct constant behavior.
- Proof obligations: PO-001, PO-005.
- Status: no changes made to `BaseExpression` or `Value`; the wrapper is the
  only defective dispatch point.

## F-004: Machine checking and runtime execution are unavailable by instruction

- Classification: proof capability gap, not a code bug.
- Evidence: task instruction forbids tests, Python execution, and K tooling.
- Input: emitted commands in `fvk/PROOF.md`.
- Observed behavior: commands are written but not executed.
- Expected behavior: artifacts are labeled constructed, not machine-checked.
- Proof obligations: PO-006.
- Status: accepted residual risk; no tests are removed or claimed redundant
  unconditionally.

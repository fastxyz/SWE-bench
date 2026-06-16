# FVK Iteration Guidance

Status: V2 keeps V1's main design and applies one small consistency improvement.

## Decision

V1's core fix stands: a private `_latex_power_base` hook on `Creator` is an
adequate, targeted way to group daggered secondquant creation operators only
when they are used as power bases.

V2 additionally tightens the folded fractional-power branch so that a custom
power-base hook cannot be bypassed by the function-specific fallback. This is
justified by F2 and PO2.

## Recommended Source State

Keep:

- `Creator._latex_power_base` returning the direct operator LaTeX wrapped in
  braces.
- Standard power-path lookup of `_latex_power_base`.
- Folded fractional power-path lookup of `_latex_power_base`.
- Direct `_latex` methods for `CreateBoson` and `CreateFermion` unchanged.

Do not add:

- Outer braces to direct `CreateBoson._latex` or `CreateFermion._latex`; F3 and
  PO4 require direct output to remain unchanged.
- A broad `parenthesize_super` change for every non-symbol base; F4 and PO5
  require unrelated printer behavior to remain on legacy paths.
- State-label rendering changes; F5 records that as outside the public evidence
  for this issue.

## Follow-Up Tests to Add Outside This Benchmark

The project test suite is fixed and hidden for this task, so no tests were
edited. In a normal development flow, add focused tests for:

- `latex(Bd(Symbol('0'))**2) == r"{b^\dagger_{0}}^{2}"`.
- `latex(Fd(p)**2) == r"{a^\dagger_{p}}^{2}"`.
- `latex(Bd(i)) == r"b^\dagger_{i}"` remains unchanged.
- A non-creator superscripted symbol still follows existing
  `parenthesize_super` behavior.

Do not remove existing tests unless the K claims are later machine-checked and
the test is wholly subsumed by the checked contract.


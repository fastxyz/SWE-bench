# FVK Findings

Status: constructed, not machine-checked. No tests, Python, or K tooling were
run.

## F1 - Resolved Code Bug: Standard Powers of Daggered Creators

Input: a standard power whose base prints as `b^\dagger_{0}` and exponent
prints as `2`.

Observed in pre-fix behavior from the public issue:
`b^\dagger_{0}^{2}`.

Expected from public intent ledger entries E2 and E3:
`{b^\dagger_{0}}^{2}`.

Classification: code bug in LaTeX formatting.

V2 status: resolved by `Creator._latex_power_base` and the standard power path
in `LatexPrinter._helper_print_standard_power`.

Proof obligations: PO1, PO3.

## F2 - Resolved Consistency Gap: Folded Fractional Powers Also Append an Outer Power

Input: a folded fractional power whose base is a secondquant creation operator,
for example a base printed as `b^\dagger_{i}` and a folded exponent `3/4`.

Observed in V1 before the FVK adjustment: the branch already consulted
`_latex_power_base`, but its function-specific fallback was not explicitly
guarded by `custom_base is None`. Current in-tree creators are not functions, so
this was not a user-visible failure for the reported issue.

Expected from intent ledger E8 and proof obligation PO2: when a custom grouped
power base exists, that hook wins in every branch that appends an outer power.

Classification: proof-derived robustness and consistency gap.

V2 status: resolved by changing the folded fractional branch to enter the
function-specific fallback only when no custom power-base hook is present.

Proof obligations: PO2, PO5.

## F3 - Confirmed Frame Condition: Direct Creator LaTeX Remains Unchanged

Input: direct `latex(Bd(i))` or `latex(Fd(p))` without an outer power.

Observed public expectations: `b^\dagger_{i}` and `a^\dagger_{p}`.

Expected from intent ledger E4 and E5: unchanged direct output.

Classification: frame condition confirmed by source inspection.

V2 status: no additional source edit needed. The new method is only consulted by
power printing; direct `_latex` implementations are unchanged.

Proof obligations: PO4.

## F4 - Confirmed Frame Condition: Non-Creator Power Printing Remains on Legacy Paths

Input: symbols with superscripts, functions, derivatives, non-creator bases,
negative rational commutative powers, and root-notation powers.

Expected from intent ledger I4 and E6: preserve existing behavior.

Classification: frame condition confirmed by source inspection.

V2 status: no additional source edit needed. Objects without
`_latex_power_base` follow the previous code paths.

Proof obligations: PO5.

## F5 - Residual Scope Note: State Label Rendering Is Existing Behavior

Input class: creation-operator states whose labels are not handled by the
existing `self.state.name` formatting.

Observed code fact: `CreateBoson._latex` and `CreateFermion._latex` still use
`self.state.name`.

Expected from this issue: no public obligation to redesign state-label
formatting; the prompt uses `Symbol('0')` and identifies the outer double
superscript as the bug.

Classification: residual risk outside this issue's proven scope, not a blocking
finding for the requested fix.

V2 status: no source edit. Changing state label printing would exceed the
publicly evidenced defect and could alter unrelated output.

Proof obligations: PO6.


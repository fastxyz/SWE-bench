# FVK Findings

Status: all code findings for the targeted issue are resolved by V1. Proof is
constructed, not machine-checked.

## F-001: All-nonfinite x representatives used to leak `StopIteration`

- Classification: code bug, resolved.
- Evidence: E-001, E-004, E-006.
- Input: `ax.bar([np.nan], [np.nan])` and `ax.bar([np.nan], [0])`.
- Observed before V1: `_convert_dx` called `_safe_first_finite(x0)`;
  `_safe_first_finite` raised `StopIteration` because there was no finite
  element; the exception escaped before bar creation.
- Expected: representative selection falls back to the first unfiltered element
  when no finite element exists, allowing bar creation with nonfinite geometry.
- Resolution: V1 catches `StopIteration` for both `x0` and `xconv` and calls
  `cbook.safe_first_element`.
- Proof obligation: PO-001 and PO-002.

## F-002: Mixed leading-NaN behavior must not regress

- Classification: regression guard, resolved.
- Evidence: E-005.
- Input class: x data begins with `NaN` but contains a later finite value.
- Potential bad fix: always use the first element, which would reintroduce the
  older leading-NaN issue described in the release-note hint.
- Expected: when a finite element exists, `_safe_first_finite` still selects it.
- Resolution: V1 catches only `StopIteration`; `_safe_first_finite` still wins
  for mixed data.
- Proof obligation: PO-003.

## F-003: Empty-bar behavior is context, not a requested fix

- Classification: underspecified alternative, no code change.
- Evidence: E-008 and E-009.
- Input: `ax.bar([], [])`.
- Observed/intended context: empty bar data returns an empty container, which is
  why seaborn uses a phantom NaN bar for color-cycle advancement.
- Expected for this issue: keep the existing empty-`xconv` branch in
  `_convert_dx`; do not change artist cardinality for empty bar data without a
  separate public requirement.
- Proof obligation: PO-004.

## F-004: Full rendering behavior is beyond this mini semantics

- Classification: proof capability boundary, not a code bug.
- Evidence: SPEC_AUDIT rendering-scope entry.
- Input: backend drawing, autoscaling, and renderer-specific behavior after the
  rectangle is created.
- Observed: not executed or modeled.
- Expected: this audit only proves the conversion path no longer aborts with
  `StopIteration`.
- Recommendation: keep integration/rendering tests. Do not remove tests based
  on this constructed proof unless the emitted K claims are machine-checked and
  the tests are proven in-domain.

## F-005: No compatibility break found

- Classification: compatibility audit, resolved.
- Evidence: PUBLIC_COMPATIBILITY_AUDIT.
- Input/callsite class: existing internal callers of `_convert_dx`.
- Observed in V1: signature and caller protocol are unchanged.
- Expected: public `Axes.bar`/`barh` behavior improves for all-nonfinite x data
  without requiring downstream API changes.
- Proof obligation: PO-007.

## Proof-Derived Findings From `/verify`

No additional code defect surfaced. The proof obligations exposed two important
scope boundaries:

- The proof relies on the intent-derived non-empty-coordinate domain for the
  all-NaN repair. Empty input remains a separate behavior and is not used to
  justify V1.
- The proof is constructed only. K commands are recorded in `PROOF.md` but were
  not run, so test deletion would be premature.

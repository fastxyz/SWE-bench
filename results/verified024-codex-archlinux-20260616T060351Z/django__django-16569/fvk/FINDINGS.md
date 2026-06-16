# FVK Findings

Status: constructed from public intent, source inspection, and the proof
obligations. No tests or code were executed.

## F1 - Original empty-form bug is discharged by V1

- Classification: code bug fixed.
- Input/state: `can_delete=True`, `can_delete_extra=False`, `index=None`,
  `initial_form_count=0` or any nonnegative count.
- V0 observed behavior: evaluating `index < initial_form_count` attempted
  `None < int` and raised `TypeError`.
- Expected behavior: `empty_form` should be constructed; no `DELETE` field is
  added because extra deletion is disabled.
- Evidence: E1, E2, E3, E4, E6.
- Proof obligations: PO1, PO2, PO3c.
- V1 status: discharged. The condition now evaluates `index is not None`
  before any numeric comparison.

## F2 - Indexed form behavior remains covered

- Classification: preservation finding.
- Input/state: `can_delete=True`, `can_delete_extra=False`, numeric
  nonnegative `index`, `initial_form_count=N`.
- Observed V1 behavior by inspection: `DELETE` is added iff `index < N`.
- Expected behavior: initial indexed forms keep `DELETE`; extra indexed forms
  omit it.
- Evidence: E4 and E5.
- Proof obligations: PO3d, PO3e, PO4.
- V1 status: discharged. The added `index is not None` guard is true for
  ordinary numeric indexes, so the indexed comparison is preserved.

## F3 - Compatibility audit finds no required source changes

- Classification: compatibility confirmation.
- Input/state: public callers and overrides of `add_fields(form, index)`.
- Expected behavior: same signature, same `index=None` convention, same
  subclass dispatch, no new keyword or return protocol.
- Evidence: E6, E7, E8 and `PUBLIC_COMPATIBILITY_AUDIT.md`.
- Proof obligations: PO4, PO5.
- V1 status: discharged. No source edit beyond V1 is justified.

## F4 - Nonstandard manual indexes remain outside the audited public domain

- Classification: default-domain assumption.
- Input/state: direct manual calls to `add_fields(form, index)` with negative
  integers or non-integer, non-`None` objects.
- Public intent: not specified by the issue, docs, or public tests audited
  here. The documented special non-integer value is `None` for `empty_form`.
- Expected behavior: no new code change is justified without clarification.
- Evidence: E6 and I8.
- Proof obligations: PO1.
- V1 status: accepted as out of scope for this repair.

## Proof-derived findings from `/verify`

No proof obstacle required a V2 source change. The adequacy gate passes:
`FORMAL_SPEC_ENGLISH.md` matches `INTENT_SPEC.md`, and
`PUBLIC_COMPATIBILITY_AUDIT.md` has no unhandled public caller or override.

The proof remains constructed, not machine-checked. This is a verification
honesty limitation, not a code bug. Test removal would be conditional on a
future `kprove` run returning `#Top`; no tests were modified.

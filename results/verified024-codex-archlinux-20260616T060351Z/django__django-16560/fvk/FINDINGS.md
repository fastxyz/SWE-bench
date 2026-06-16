# Findings

Status: constructed, not machine-checked.

## Summary

No V2 source-code defect was found in the V1 patch. The V1 code satisfies the
public-intent proof obligations for validation error code customization on all
constraint-message validation paths.

## Findings

F-001 - Resolved baseline defect: no custom code path.

- Input/class: a violated `CheckConstraint`, expression `UniqueConstraint`,
  conditional `UniqueConstraint`, or `ExclusionConstraint` constructed with
  `violation_error_code="custom_code"`.
- V0 observed behavior from source: validation raised `ValidationError` with no
  custom code because the relevant raises passed only the message.
- Expected behavior from E-1 through E-3: the raised `ValidationError.code`
  equals `"custom_code"`.
- V1/V2 status: discharged by PO-4, PO-5, and PO-6.

F-002 - Resolved lifecycle preservation defect.

- Input/class: any built-in constraint constructed with
  `violation_error_code="custom_code"` and then deconstructed or cloned.
- V0 observed behavior from source: no constructor storage/deconstruction field
  existed for the code, so the value could not be preserved.
- Expected behavior from I-3: the code survives migration serialization and
  cloning.
- V1/V2 status: discharged by PO-1 and PO-3.

F-003 - Confirmed legacy branch: field-only `UniqueConstraint` without condition.

- Input/class: violated `UniqueConstraint(fields=[...], condition=None,
  violation_error_code="custom_code")`.
- Candidate behavior: validation still delegates to `unique_error_message()`.
- Expected behavior from E-5: this branch is the documented exception for
  `violation_error_message`; by analogy, the new code parameter does not override
  it in this repair.
- V1/V2 status: no source change required; tracked by PO-5.

F-004 - Confirmed compatibility of optional API extension.

- Input/class: existing callers that omit `violation_error_code`.
- Expected behavior from I-6: old behavior remains valid and error code defaults
  to `None`.
- V1/V2 status: discharged by PO-2 and PO-8.

F-005 - Residual documentation-sync follow-up.

- Input/class: public docs pages that list constraint constructor signatures.
- Observed from source docs: the snippets still mention only
  `violation_error_message`.
- Expected for a full project documentation update: docs should mention
  `violation_error_code`.
- V1/V2 status: not a benchmark source-code correctness blocker; recorded as a
  follow-up in `ITERATION_GUIDANCE.md`.


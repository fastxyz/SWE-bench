# FVK Notes

## Decision

V1 stands unchanged. The FVK audit did not surface a runtime source defect that
requires a V2 code edit.

## Trace to findings and proof obligations

- The reported defect is F-001. It is closed by PO-2 and PO-3: V1 passes
  `params={'value': value}` when raising `invalid_choice` and changes the
  default message to include `%(value)s`.
- Empty values and valid queryset lookups are covered by PO-4. V1 does not edit
  those branches, so preserving them is justified by source control-flow
  inspection and the K claims `EMPTY-VALUE` and `VALID-SUBMITTED`.
- Value identity for correct-model instances is covered by PO-5. I kept V1's
  behavior of reporting the lookup key after the existing conversion because
  that is the value actually used by `queryset.get()`.
- F-002 explains why old default-message expectations should not cause a revert:
  they encode the behavior named as buggy in the public issue.
- F-003 records the only compatibility risk from adding params. I accepted it
  under PO-6 because the public issue asks for params and the same interpolation
  convention already applies to other choice fields.
- F-004 is a non-blocking documentation gap. I did not edit docs because the
  runtime source obligations for this task are discharged, but the guidance
  records a docs follow-up.
- F-005 and PO-7 record the honesty gate: I did not run tests, Python, or K
  tooling, and the proof is constructed rather than machine-checked.

## Code changes in this FVK phase

None. The only files added in this phase are FVK artifacts under `fvk/` and this
report.


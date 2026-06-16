# Iteration Guidance

Status: constructed from the FVK audit, not machine-checked.

## Source decision

Keep V1 unchanged.

Reason: the proof obligations for the runtime issue are discharged by the V1
source diff:

- PO-2 requires `params={'value': value}` on invalid-choice errors.
- PO-3 requires `%(value)s` in the default message.
- PO-4 requires valid and empty behavior to remain unchanged.

No additional source-code defect was found.

## Follow-up recommendations

1. Add or update tests, outside this task, that assert
   `ModelChoiceField(queryset=..., error_messages={'invalid_choice':
   '%(value)s IS INVALID'}).clean(invalid)` renders the submitted invalid
   value.
2. Update legacy tests that assert the old default message; those are suspect
   under F-002.
3. Consider a documentation update for `docs/ref/forms/fields.txt` so the
   `ModelChoiceField` section explicitly says `invalid_choice` may contain
   `%(value)s`, mirroring the docs for `ChoiceField` and
   `ModelMultipleChoiceField`.
4. Run the K commands in `PROOF.md` and Django's relevant form/model tests in a
   real execution environment. This session intentionally did not run them.


# Iteration Guidance

Status: constructed for FVK audit; not machine-checked.

## Verdict

V1 stands unchanged. The audit found no public-intent or proof-obligation
failure requiring another source edit.

## Decisions for This Iteration

- Keep the V1 source change in `repo/django/template/defaultfilters.py`.
  Reason: F-001 and F-002 are discharged by PO-2 through PO-4.
- Do not broaden the fix into `django.utils.functional.lazy()`.
  Reason: F-004 and PO-7 show the reported failure is local to the filter
  fallback and a global proxy change would have a larger compatibility surface.
- Do not force every `Promise`.
  Reason: PO-6 preserves non-text lazy behavior, while E-7 gives enough public
  evidence for text promises created by `gettext_lazy()`.
- Do not modify tests.
  Reason: the task forbids test edits; F-005 also says test removal must be
  conditioned on machine-checking.

## Suggested Future Tests

These are recommendations only and were not added:

- Direct filter call: `add("hello ", gettext_lazy("world")) == "hello world"`.
- Template render: `{{ value|add:lazy_value }}` with a normal string and a
  `gettext_lazy()` value.
- Numeric lazy text: `add("1", gettext_lazy("2")) == 3`.
- Regression frame tests for existing integer, list, tuple, date/timedelta, and
  incompatible-type behavior.

## Future Verification Work

- In a real K environment, run the commands recorded in `PROOF.md`.
- If future public intent broadens "lazy string" beyond Django text promises
  marked with `_delegate_text`, add a new evidence-ledger entry and a new proof
  obligation before changing the code.


# FVK Notes

## Decision Summary

V1 is confirmed and stands unchanged. No source files were edited during the FVK
phase.

## Trace to Findings and Proof Obligations

- Kept `repo/django/db/models/manager.py` unchanged because F-001 confirms that
  `@wraps(method)` addresses the reported `inspect.signature()` defect, and
  PO-001 through PO-003 explain why the `__wrapped__` metadata is sufficient for
  bound-method signature recovery.
- Did not replace `wraps()` with a manually assigned `__signature__` because
  F-002 and PO-004 require a generic relationship to the current queryset method
  signature, not a hard-coded parameter list derived from the issue example.
- Did not change the queryset method filtering loop because F-003 and PO-005
  show that the eligibility rules are outside the bug and remain preserved by V1.
- Did not change the forwarding call body because F-003 and PO-006 show that the
  runtime call behavior already remains unchanged.
- Accepted the broader metadata copying done by `functools.wraps()` because
  F-004 ties it directly to the public issue's "complete metadata" requirement
  and PO-002 lists the metadata preserved by the repair.
- Did not run tests, Python snippets, or K tooling because the task forbids
  execution. F-005 and PO-007 record this as an honesty-gate limitation, not as
  evidence against the code.

## Alternatives Considered

- Hard-coding `manager_method.__signature__` was rejected because it would solve
  only signature display, would need careful binding behavior, and would not
  address the public requirement to copy complete wrapper metadata.
- Changing `QuerySet.bulk_create()` or any other queryset method was rejected
  because F-002 shows the queryset method signature is the source of truth; the
  defect is only in the manager proxy metadata.
- Adding tests was not considered an allowed action in this benchmark phase,
  since test files are fixed and hidden.

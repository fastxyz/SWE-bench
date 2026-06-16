# FVK Iteration Guidance

Status: V1 confirmed; no production-code edit is required by this FVK pass.

## Decision

Keep V1 unchanged.

The FVK audit confirms that the saved-instance branch must generate a
primary-key password URL independent of the current change URL object segment
(F-001, PO-1, PO-2). V1 does that. The audit also confirms that admin quoting is
the right strengthening over the raw-pk issue suggestion (F-002, PO-5).

## Decisions Traced to Findings and Obligations

1. Keep `../../%s/password/ % quote(self.instance.pk)` for saved instances.
   Trace: F-001, F-002, PO-1, PO-2, PO-5.
2. Keep the `../password/` fallback when `self.instance.pk is None`.
   Trace: F-004, PO-4.
3. Do not change `UserAdmin.user_change_password()` to accept `_to_field`.
   Trace: F-003, PO-2, PO-3.
4. Do not replace the relative URL with `reverse()`.
   Trace: F-003; the form lacks request/admin-site context.
5. Do not edit tests.
   Trace: F-005, PO-7, task instruction forbidding test edits.

## Suggested Future Public Tests

Add an admin integration test that opens a user change form through a non-primary
`to_field` object segment and asserts that joining the help-text relative link
lands on the primary-key password-change URL.

Add a focused test for a string primary key containing an admin path-special
character if a suitable admin test model is already available. This would guard
the quote-preserving part of V1.

## Machine Check Deferred

The constructed proof commands are listed in `fvk/PROOF_OBLIGATIONS.md` as PO-7
and were not executed in this session.

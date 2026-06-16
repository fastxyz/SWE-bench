# FVK Notes

## Decision

V1 stands unchanged. The FVK audit found that the V1 source edit satisfies the
intent-derived URL obligations and that the extra admin quoting in V1 is a
justified improvement over the raw primary-key interpolation suggested in the
issue text.

## Trace to Findings and Proof Obligations

The decision to keep the saved-instance URL as
`../../%s/password/` with `quote(self.instance.pk)` is justified by F-001 and
F-002. PO-1 proves the saved form uses the admin-quoted primary key segment.
PO-2 proves this fixes the reported `to_field` path by resolving to the primary
key expected by `UserAdmin.user_change_password()`. PO-5 records the quote/
unquote side condition needed for unusual primary-key values.

The decision to keep the `../password/` fallback when `self.instance.pk is None`
is justified by F-004 and PO-4. That preserves existing public form
instantiation behavior and avoids introducing a `None` path segment for forms
that are not editing a saved admin object.

The decision not to edit `UserAdmin.user_change_password()` is justified by
F-003, PO-2, and PO-3. The password view already has a primary-key route and the
bug is the help link pointing at a non-primary object segment. Changing the view
to honor `_to_field` would widen behavior beyond the reported broken link.

The decision not to replace the relative link with `reverse()` is justified by
F-003. `UserChangeForm` does not have request or admin-site context, while the
relative URL has enough information to satisfy PO-2 and PO-3.

The decision not to edit tests is required by the task and reinforced by F-005
and PO-7. The proof is constructed, not machine-checked, and K/test execution is
forbidden in this session.

## Artifacts Produced

The five requested FVK artifacts are:

- `fvk/SPEC.md`
- `fvk/FINDINGS.md`
- `fvk/PROOF_OBLIGATIONS.md`
- `fvk/PROOF.md`
- `fvk/ITERATION_GUIDANCE.md`

To satisfy the FVK documentation's formal-core requirement, I also added:

- `fvk/mini-admin-url.k`
- `fvk/user-change-form-spec.k`

## Code Changes in This FVK Pass

No production source files were changed during the FVK pass. The V1 change in
`repo/django/contrib/auth/forms.py` remains the final code fix.

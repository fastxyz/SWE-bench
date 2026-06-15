# FINDINGS

Status: V1 confirmed. No production code changes are required by this FVK pass.

## F1 - Closed code bug: view permission was previously a write permission for auto-created m2m inlines

- Classification: code bug in pre-V1 behavior, fixed by V1.
- Evidence: `benchmark/PROBLEM.md` reports that a user with only view permissions can add/remove through `Report.photos.through`.
- Observed in pre-V1 code: `InlineModelAdmin.has_add_permission()`, `has_change_permission()`, and `has_delete_permission()` returned `self.has_view_permission()` for `self.opts.auto_created`.
- Expected: view-only users may view the relation but must not edit it.
- V1 status: fixed. Write hooks now require target model `change`.
- Proof obligations: PO1, PO2, PO3, PO4.

## F2 - Rejected alternative: target add/delete permissions should control relationship add/remove

- Classification: rejected interpretation.
- Evidence: public tests for auto-created m2m inlines say target `add_book` alone still means "No change permission on Books, so no inline", while target `change_book` means add/change/delete inlines are available.
- Decision: keep V1's target `change` write gate for all relationship row writes.
- Proof obligations: PO2, PO5.

## F3 - Rejected alternative: block view-only display entirely

- Classification: rejected interpretation.
- Evidence: the issue is about view-only users editing data, not about visibility of viewable relationships.
- Decision: keep V1's `has_view_permission()` behavior: target `view` or `change` can display the auto-created m2m inline, while target `change` is required for edits.
- Proof obligations: PO1, PO3.

## F4 - Rejected broader change: require parent model change permission for auto-created m2m inline writes

- Classification: scope and compatibility finding.
- Evidence: Django admin has existing save handling for editable inline formsets independent of parent form editability. Existing public tests for this m2m path set parent change permission and vary target permissions, identifying target `change` as the relevant write gate.
- Decision: do not add a new parent-change requirement in this fix. The public issue is discharged by preventing target-view-only users from editing the relation.
- Proof obligations: PO5, PO6.

## F5 - Proof status caveat

- Classification: proof process caveat, not a code bug.
- Evidence: task instructions prohibit running K tooling.
- Status: K artifacts and proof are constructed, not machine-checked. The exact commands are in `PROOF.md`.
- Proof obligations: PO7.

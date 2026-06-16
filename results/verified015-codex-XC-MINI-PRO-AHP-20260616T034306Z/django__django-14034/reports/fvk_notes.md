# FVK Notes

## Decision

V1 stands unchanged. The FVK audit produced no finding that justifies a source
edit beyond the existing V1 patch.

## Trace to Findings and Proof Obligations

F1 traces to PO-1, PO-2, and PO-3. These obligations show that V1 separates the
parent `MultiValueField.required` bit from per-subfield required bits and then
uses the child state when `require_all_fields=False`. This directly addresses
the reported rendering failure, so no additional source edit is needed for the
main issue.

F2 traces to PO-6. The public issue discussion and visible validation frame say
an optional parent `MultiValueField` may be skipped when all subfields are empty.
V1 did not edit `MultiValueField.clean()`, and the audit confirms that keeping
validation unchanged is intentional rather than an omission.

F3 traces to PO-4. The visible required-all rendering frame remains intact
because `MultiWidget.require_all_fields` defaults to `True` and V1's child
required-attr rewrite only runs when the flag is false.

F4 traces to PO-5. Optional parent fields do not receive a parent `required`
attr from `BoundField.build_widget_attrs()`, so V1 does not accidentally force
browser-required children in the all-empty optional-parent case.

F5 traces to PO-8. The proof artifacts are constructed but not machine-checked
because the task forbids running K tooling, Python, or tests. This blocks any
test-removal recommendation and is why the notes recommend future tests rather
than modifying tests here.

PO-7 found no public compatibility issue: V1 changes no public method
signature, no caller contract, and no subclass override requirement. The added
`MultiWidget.require_all_fields` default preserves standalone `MultiWidget`
behavior.

## Code Changes in This FVK Pass

No source files under `repo/` were changed during the FVK pass. The only files
added are FVK artifacts under `fvk/` and this report.


# PROOF OBLIGATIONS

Status: constructed, not machine-checked.

## PO1 - Explicit Parent-Link Discriminator

Statement: `parent_links` may be updated only by fields satisfying both `isinstance(field, OneToOneField)` and `field.remote_field.parent_link`.

Evidence: Intent entries E3 and E5.

Discharged by: V2 source diff in `repo/django/db/models/base.py`; K semantics rule for `field(_, _, true, true)`.

Related findings: F1.

## PO2 - Order Independence From Ordinary Fields

Statement: For a field list containing exactly one explicit parent link to parent `P` and any ordinary one-to-one fields to `P`, the selected parent-link entry for `P` is the explicit parent-link field, independent of whether ordinary fields appear before or after it.

Evidence: Intent entries E1 and E2.

Discharged by: K claims C1 and C2; source inspection shows ordinary fields fail the `field.remote_field.parent_link` guard and therefore cannot update the map.

Related findings: none after V2.

## PO3 - Ordinary One-To-One Fields Are Not Parent Links

Statement: A `OneToOneField` with `remote_field.parent_link == False` contributes no declared parent-link entry even when it targets a concrete parent model.

Evidence: Intent entries E4 and E5.

Discharged by: K claim C3 and V2 source guard.

Related findings: F1, F2.

## PO4 - Auto-Created Parent Pointer Path Remains Reachable

Statement: If no explicit parent link exists for a concrete parent, `base_key not in parent_links` remains true when concrete parent handling runs, so the existing `OneToOneField(... auto_created=True, parent_link=True)` branch can execute.

Evidence: Intent entry E6 and source lines after parent-link collection.

Discharged by: K claim C3 establishes the empty map for ordinary fields; source inspection confirms the existing `elif not is_proxy:` branch creates the pointer when `base_key` is absent.

Related findings: F1, F2.

## PO5 - Abstract Parent-Link Discovery Preserved

Statement: Explicit parent links declared on the new class or abstract bases continue to be discovered.

Evidence: existing source loop scans `reversed([new_class] + parents)` and skips only concrete parent classes.

Discharged by: V2 retains the same traversal and only narrows eligible fields to explicit parent links, which is the intended signal.

Related findings: none.

## PO6 - Public Compatibility

Statement: The repair must not change public signatures or data shapes outside the intended parent-link behavior.

Evidence: `PUBLIC_COMPATIBILITY_AUDIT.md`.

Discharged by: no public API signature changed; `parent_links` retains the same key/value shape.

Related findings: F2.

## PO7 - Duplicate Explicit Parent Links Are Outside This Spec

Statement: Behavior for two explicit parent links to the same related model is not proven as an intended public behavior.

Evidence: no public issue/docs evidence identifies the desired winner or error behavior.

Discharged by: recorded as underspecified in F3. No source change is justified by this issue.

Related findings: F3.

## PO8 - Honesty Boundary

Statement: The proof must be labeled constructed, not machine-checked, and no tests may be removed or inferred from nonexistent results.

Evidence: task forbids running tests, Python, or K tooling.

Discharged by: `PROOF.md` records commands without executing them; no test files were modified.

Related findings: F4.

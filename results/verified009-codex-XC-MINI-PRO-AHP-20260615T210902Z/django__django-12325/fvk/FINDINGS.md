# FINDINGS

## F1 - V1 Preserved a Legacy-Derived Candidate Path

Input: `class Picking(Document): parent = OneToOneField(Document, on_delete=CASCADE)` with no `parent_link=True`.

V1 observed-by-inspection: because `related_name is None`, V1 still stored the ordinary field in `parent_links`, causing the later `_prepare()` path to raise `ImproperlyConfigured: Add parent_link=True ...`.

Expected by public intent: an ordinary `OneToOneField` is not a parent link unless `parent_link=True`; if no explicit parent link exists, Django's automatic parent pointer path should remain available.

Evidence: `PUBLIC_EVIDENCE_LEDGER.md` entries E3, E5, and E6. The exception is also the issue's reported symptom for ordinary one-to-one fields.

Classification: code bug in V1; legacy-derived side condition.

Resolution: V2 removes the `related_name is None` candidate path and filters parent-link collection to `isinstance(field, OneToOneField) and field.remote_field.parent_link`.

Proof obligations: PO1, PO3, PO4.

## F2 - Public Legacy Test Is SUSPECT

Input: `repo/tests/invalid_models_tests/test_models.py::InvalidModelTestCase.test_missing_parent_link`.

Observed public test expectation: class construction raises `ImproperlyConfigured` for a child model declaring `parent = OneToOneField(Place, CASCADE)`.

Expected by issue/docs intent: the parent-link discovery step should not treat an ordinary one-to-one field as the inheritance link solely because it targets the parent model.

Evidence: `benchmark/PROBLEM.md` reports the same error against `some_unrelated_document` as the bug; docs say `parent_link=True` indicates a custom inheritance link and that Django otherwise creates the child-parent pointer.

Classification: SUSPECT public test / stale legacy behavior. It should not veto the issue-derived spec.

Resolution: no test edits, per task constraints. V2 prioritizes public issue/docs intent.

Proof obligations: PO3, PO4, PO6.

## F3 - Multiple Explicit Parent Links to the Same Parent Remain Underspecified

Input: two local `OneToOneField`s to the same parent, both with `parent_link=True`.

Observed source behavior: the later explicit parent-link field overwrites the earlier one because the map key is the related model tuple.

Expected by public intent: not specified by the issue. The issue only requires ordinary fields not to displace the explicit parent link.

Classification: underspecified intent, not a blocker for this repair.

Resolution: left unchanged. A future issue should clarify whether duplicate explicit parent links should be rejected or last-wins.

Proof obligations: PO7.

## F4 - Proof Constructed, Not Machine-Checked

Input: all K claims in `modelbase-parent-links-spec.k`.

Observed: this workspace has no execution environment and the task forbids running K tooling.

Expected: artifacts record the exact `kompile` and `kprove` commands and label the proof constructed, not machine-checked.

Classification: proof honesty boundary.

Resolution: no commands executed; commands are recorded in `PROOF.md`.

Proof obligations: PO8.

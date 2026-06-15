# FVK Notes

## Decisions

1. Replaced the V1 parent-link selection logic with a stricter `parent_link=True` filter in `repo/django/db/models/base.py`.

   Trace: `fvk/FINDINGS.md` F1 identifies V1's `related_name is None` branch as a legacy-derived candidate path. `fvk/PROOF_OBLIGATIONS.md` PO1 requires parent-link map updates only for `OneToOneField` instances whose `remote_field.parent_link` is true. PO3 requires ordinary one-to-one fields not to become parent links. PO4 requires the auto-created parent pointer path to remain reachable when no explicit parent link exists.

2. Treated the existing public `test_missing_parent_link` behavior as suspect rather than preserving it in production code.

   Trace: `fvk/FINDINGS.md` F2 records that the test expects the same error shape described by the issue as the bug. `fvk/PROOF_OBLIGATIONS.md` PO3 and PO4 conflict with that legacy expectation, and PO6 records that the behavioral compatibility change is intentional while public APIs remain unchanged.

3. Kept traversal order and map shape otherwise unchanged.

   Trace: `fvk/PROOF_OBLIGATIONS.md` PO2 only requires ordinary fields not to affect the explicit parent-link winner. PO5 requires preserving explicit parent links declared on the new class or abstract bases. The V2 edit narrows eligibility but leaves `reversed([new_class] + parents)`, `resolve_relation()`, and `make_model_tuple()` unchanged.

4. Did not attempt to define new behavior for duplicate explicit parent links to the same parent.

   Trace: `fvk/FINDINGS.md` F3 marks that case underspecified. `fvk/PROOF_OBLIGATIONS.md` PO7 says no public issue/docs evidence justifies changing it in this repair.

5. Did not run tests or K tooling and did not remove tests.

   Trace: `fvk/FINDINGS.md` F4 and `fvk/PROOF_OBLIGATIONS.md` PO8 record the honesty boundary. `fvk/PROOF.md` lists the commands to run later but labels the proof constructed, not machine-checked.

## Result

V2 is smaller and better aligned with the public intent than V1. The implemented rule is: a declared field enters `parent_links` only if it is a `OneToOneField` and `field.remote_field.parent_link` is true. Ordinary one-to-one fields to a parent model no longer displace explicit parent links or block the existing auto-created parent pointer branch.

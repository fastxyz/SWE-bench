# Public Compatibility Audit

Changed public symbol: none.

Changed source location: `repo/django/db/models/base.py`, inside `ModelBase.__new__()` parent-link discovery.

Compatibility observations:

- The patch does not change a public function signature, method name, class name, return type, import path, or virtual dispatch call.
- The internal `parent_links` dictionary retains the same key/value shape: model tuple to `OneToOneField`.
- Existing downstream consumers in the same method still read `parent_links[base_key]` and receive either an explicit parent-link field or no entry, which routes to the pre-existing auto-created pointer branch.
- Public test `invalid_models_tests.test_missing_parent_link` encodes legacy class-construction error behavior that conflicts with the issue/docs intent for ordinary one-to-one fields to a parent model. It is recorded as SUSPECT in `FINDINGS.md`, not as a compatibility blocker.

Conclusion: no public API compatibility change. The behavioral compatibility change is intentional and traceable to the bug report.

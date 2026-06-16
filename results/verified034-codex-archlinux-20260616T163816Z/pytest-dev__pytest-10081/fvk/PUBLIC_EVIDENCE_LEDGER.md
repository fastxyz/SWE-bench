# Public Evidence Ledger

| ID | Source | Evidence | Semantic Obligation | Status |
| --- | --- | --- | --- | --- |
| E-001 | prompt / issue | "Running `pytest --pdb` will run the `tearDown()` of `unittest.TestCase` classes that are decorated with `unittest.skip` on the class level." | Treat class-level skipped teardown execution under `--pdb` as the defect. | Encoded in I-002 and PO-001. |
| E-002 | prompt / issue | "Test is properly skipped normally" and the normal run shows `1 skipped`. | Without `--pdb`, class-level unittest skip is expected to skip the test. | Encoded as a frame condition. |
| E-003 | prompt / issue | Under `--pdb`, output shows `sE` and `NameError` inside `tearDown`. | `--pdb` must not turn a class-level skip into a teardown error. | Encoded in class-skip claim. |
| E-004 | prompt / issue | "Identical to #7215, but with the `skip()` on the class level rather than on the function level." | The existing method-level skip rule should extend to class-level skip. | Encoded in I-004 and PO-002. |
| E-005 | public test | `test_pdb_teardown_called`: "Ensure tearDown() is always called when --pdb is given" for non-skipped tests. | Preserve delayed teardown for non-skipped synchronous unittest tests. | Encoded in PO-003. |
| E-006 | public test | `test_pdb_teardown_skipped`: "With --pdb, setUp and tearDown should not be called for skipped tests." | Method-level skipped tests must not install delayed teardown. | Encoded in PO-002. |
| E-007 | source comment | In `runtest`: "When --pdb is given, we want to postpone calling tearDown()" to preserve instance variables for debugging. | Delay is intentional only for tests that should actually run teardown. | Encoded as a frame condition. |
| E-008 | source code pattern | `_make_xunit_fixture` uses `_is_skipped(self)` on a unittest instance before xunit setup/teardown. | Instance-level skip predicate is an established local way to observe class skip metadata. | Encoded in PO-004. |
| E-009 | source code | `_is_skipped(obj)` returns `bool(getattr(obj, "__unittest_skip__", False))`. | Skip predicate observes any object carrying or inheriting `__unittest_skip__`. | Encoded in PO-004. |

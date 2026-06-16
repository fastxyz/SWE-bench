# Public Evidence Ledger

Constructed, not machine-checked.

| ID | Source | Evidence | Semantic obligation | Status |
| --- | --- | --- | --- | --- |
| E1 | `benchmark/PROBLEM.md` | "Starting v6.2.0, unittest setUpClass fixtures are no longer \"private\"" | Generated unittest setUpClass fixtures are intended to be private/internal. | Encoded in PO1 and C1. |
| E2 | `benchmark/PROBLEM.md` | "expected ... fixture's name would start with an underscore" | The privacy mechanism is the fixture registration name beginning with `_`. | Encoded in PO1, PO2, C1-C6. |
| E3 | `benchmark/PROBLEM.md` | "only get printed if the additional `-v` flag was used" | Non-verbose listing must skip underscore-prefixed generated fixtures; verbose listing may show them. | Encoded in PO3, C7-C8. |
| E4 | `benchmark/PROBLEM.md` | xunit class fixture example shows `xunit_setup_class_fixture_Tests` visible in `pytest --fixtures` | Xunit-generated fixture names are part of the affected family. | Encoded in PO2 and C3-C6. |
| E5 | `benchmark/PROBLEM.md` | "a similar change needs to be applied to the other generated fixtures" | Do not stop at the reported unittest and class-level xunit examples; cover every generated setup fixture name. | Encoded in PO5. |
| E6 | `repo/src/_pytest/python.py` | `_showfixtures_main` skips names with `argname[0] == "_"` when `verbose <= 0` | The observable hide rule depends on `fixturedef.argname`, which is supplied by explicit `name=` in the fixture decorator. | Encoded in PO3. |
| E7 | `repo/src/_pytest/python.py` and `repo/src/_pytest/unittest.py` | Each generated fixture comment says "Use a unique name to speed up lookup." | The generated names are implementation-specific identifiers, not documented public fixture APIs. | Encoded in PO4 and compatibility audit. |
| E8 | V1 source diff | Only `name=` strings changed; function bodies, scopes, autouse flags, and attachment attributes were left untouched. | The fix should restore private listing while preserving setup/teardown execution behavior. | Encoded in PO4. |

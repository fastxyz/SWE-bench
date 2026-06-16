# Public Evidence Ledger

| ID | Source | Evidence | Semantic obligation | Status |
| --- | --- | --- | --- | --- |
| E1 | prompt | "after upgrade to 5.1.2, the path was converted to lower case" | Do not lower-case conftest import paths. | Encoded by SPEC O1 and claim UNIQUE-PATH-PRESERVES-CASE. |
| E2 | prompt output | `ImportError while loading conftest 'c:\azure\...\pisys\conftest.py'` and `No module named 'python'` | The observable failing path is the path passed onward to conftest import. | Encoded by SPEC O3 and FINDING F1. |
| E3 | public hint | "If instead of using `os.normcase`, we could find a way to get the path with correct casing (`Path.resolve`?)" | Replace lowercasing with case-preserving canonicalization. | Encoded by SPEC O1/O2 and V1 implementation. |
| E4 | prompt comment | "imports a conftest from a module with upppercase characters in the package name" | Mixed-case package components are in domain. | Encoded by SPEC O1 and PO-3. |
| E5 | second report | `imageProcessing` becomes `imageprocessing` and import fails. | Preserve case for nested package components, not only final filename. | Encoded by SPEC O1 and PO-3. |
| E6 | source comment | `_importconftest`: "Use realpath to avoid loading the same conftest twice ... symlinks" | Preserve canonical same-file identity for symlink aliases. | Encoded by SPEC O2 and PO-4. |
| E7 | helper docstring | `unique_path`: "case-insensitive (but case-preserving) file systems such as Windows" | The helper's contract includes case preservation. | Encoded by SPEC O1 and PO-1. |
| E8 | in-repo public tests | `test_conftest_symlink*`, `test_conftest_badcase`, `test_setinitial_conftest_subdirs` | Conftest loading must tolerate symlinks and wrong-cased directory input. | Encoded by SPEC O2/O4 and PO-4/PO-5. |
| E9 | source API | Runtime callers import `unique_path` only in `_pytest.config`, and tests import it as a helper. | Return type and call signature should remain compatible. | Encoded by SPEC O5 and compatibility audit. |

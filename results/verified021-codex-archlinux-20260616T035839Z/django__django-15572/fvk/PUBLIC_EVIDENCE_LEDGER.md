# Public Evidence Ledger

| ID | Source | Evidence | Semantic obligation | Status |
|---|---|---|---|---|
| E1 | `benchmark/PROBLEM.md` | "Django 3.2.4+ autoreload breaks on empty string in TEMPLATES DIRS." | Empty string is the boundary case under audit. | Encoded by PO1, PO2, and Claim C1. |
| E2 | `benchmark/PROBLEM.md` | "`DIRS`: [''] # wrong will break autoreload." | `['']` must not make autoreload unusable. | Encoded by PO5 and Claim C3. |
| E3 | `benchmark/PROBLEM.md` | "the normalization transforms the empty string into the root of the project" | The bad transition is `"" -> Path('.') -> cwd`; the fix must block it before normalization. | Encoded by PO1 and PO2. |
| E4 | `benchmark/PROBLEM.md` | "template_changed() will now always return True" | Non-template files under `cwd` must not be treated as template changes solely because `DIRS` contained `""`. | Encoded by PO5 and Claim C3. |
| E5 | `repo/django/template/autoreload.py` | `get_template_directories()` collects from `backend.engine.dirs` and from loaders with `get_dirs()`. | Both sources are contributors to the observable directory set. | Encoded by PO1 and PO2. |
| E6 | `repo/django/template/loaders/filesystem.py` | `get_dirs()` returns `self.dirs` or `self.engine.dirs`. | The same invalid configured value can be reintroduced through the filesystem loader. | Encoded by PO2. |
| E7 | `repo/tests/template_tests/test_autoreloader.py` | Public tests expect relative strings and `Path` objects to normalize under `Path.cwd()`. | Non-empty relative path normalization is intended behavior. | Encoded by PO3 and PO6. |


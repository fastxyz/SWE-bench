# Public Evidence Ledger

Status: constructed from public evidence; not machine-checked.

| ID | Source | Evidence | Semantic obligation | Status |
| --- | --- | --- | --- | --- |
| E-001 | prompt | "Allow migrations directories without __init__.py files." | Namespace migrations packages are in-domain. | Encoded by PO-NS-PACKAGE. |
| E-002 | prompt | "a package with no __init__.py is implicitly a namespace package, so it has no __file__ attribute." | Missing or `None` `__file__` is not a rejection condition. | Encoded by PO-NO-FILE-GATE. |
| E-003 | prompt | "`pkgutil.iter_modules()` uses the package's `__path__` list" | Discovery depends on `__path__`. | Encoded by PO-PATH-DISCOVERY. |
| E-004 | prompt | "`__file__` check is no longer needed" | Remove old precondition; do not replace it with an equivalent file-based guard. | Encoded by PO-NO-FILE-GATE. |
| E-005 | implementation | `if not hasattr(module, '__path__'):` | Non-package modules are still unmigrated. | Encoded by PO-NONPACKAGE. |
| E-006 | implementation | `module_name is None` adds app to `unmigrated_apps`. | Disabled migrations remain unmigrated. | Encoded by PO-DISABLED. |
| E-007 | implementation | `pkgutil.iter_modules(module.__path__)` filters packages and private/backup names. | Migration discovery should continue to use the existing name filter. | Encoded by PO-FILTER. |
| E-008 | public-test, suspect | Existing `test_load_empty_dir()` expects a namespace package to be unmigrated. | This conflicts with E-001 through E-004 and is legacy-bug evidence, not a veto. | Finding F-002. |
| E-009 | downstream code | `migrate` checks membership in `executor.loader.migrated_apps`. | Correct classification is user-visible for `migrate app_label`. | Encoded by PO-MIGRATE-CONSUMER. |

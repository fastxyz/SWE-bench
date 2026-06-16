# Public Evidence Ledger

| ID | Source | Quote or local evidence | Obligation |
| --- | --- | --- | --- |
| E1 | `benchmark/PROBLEM.md` | "autodoc: empty `__all__` attribute is ignored" | Treat empty explicit `__all__` as a bug-relevant boundary case. |
| E2 | `benchmark/PROBLEM.md` | Reproducer: `__all__ = []`, functions `foo`, `bar`, `baz`, and `.. automodule:: example` with `:members:` | The contract covers `want_all=True` for a module with a valid empty export list. |
| E3 | `benchmark/PROBLEM.md` | "No entries should be shown because `__all__` is empty." | Default documented member output must be empty for the reproducer. |
| E4 | `repo/sphinx/util/inspect.py` | `getall()` returns `None` only when `__all__` is absent and returns a valid list/tuple sequence otherwise. | Formal domain must distinguish `None` from `[]` and `()`. |
| E5 | `repo/tests/test_ext_autodoc.py` | `test_autodoc_ignore_module_all` expects ignored module `__all__` to document implicit members. | Preserve the `None`/ignored path. |
| E6 | `repo/tests/test_ext_autodoc_events.py` | Event handler returns `False` to show a member not in `__all__`. | Preserve skip-event override compatibility. |
| E7 | `reports/baseline_notes.md` | V1 changed `if not self.__all__:` to `if self.__all__ is None:`. | Candidate fix to audit against the public obligations. |

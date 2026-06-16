# Public Evidence Ledger

| ID | Source | Evidence | Obligation |
| --- | --- | --- | --- |
| E1 | `benchmark/PROBLEM.md:3` | "Allow autoreloading of `python -m custom_module runserver`" | Preserve the full module name for `python -m` restarts. |
| E2 | `benchmark/PROBLEM.md:8-9` | The buggy dotted module example reports `foo.bar.baz` becoming `foo.bar`. | Dotted ordinary modules must use `__spec__.name`, not parent. |
| E3 | `benchmark/PROBLEM.md:18` | Public hint recommends exact `__main__` or suffix `.__main__`, avoiding `foo.my__main__`. | Package-main detection must not strip arbitrary names containing `__main__`. |
| E4 | `repo/tests/utils_tests/test_autoreload.py:167-183` | Existing public tests expect package `__main__` restarts with the package name. | Preserve `python -m django` and package fixture behavior. |
| E5 | `repo/tests/utils_tests/test_autoreload.py:185-230` | Existing public tests cover warn options, path fallbacks, and missing-script error. | Preserve fallback branches outside the `-m` case. |
| E6 | `repo/django/utils/autoreload.py:223-225` | Code comment identifies `__spec__` as the `-m` detection mechanism and notes it may be absent. | Treat absent or unusable specs as fallback states. |
| E7 | `repo/django/utils/autoreload.py:258-263` | `restart_with_reloader()` calls `get_child_arguments()` and passes the list to `subprocess.run()`. | Preserve signature and command-list return shape. |

# Baseline notes — pytest-dev__pytest-6197

## Issue

Regression in pytest 5.2.3: pytest tries to **import every `__init__.py`** found under
the rootdir during collection, even for packages that contain no tests. A directory such
as

```
foobar/__init__.py   # contains `assert False` (or Django settings, win-only code, ...)
test_foo.py
```

makes collection fail with `ERROR collecting foobar/__init__.py` because `foobar/__init__.py`
is imported even though nothing in it is (or should be) collected. The public hints point at
PR #5831 (which fixed #5830 — *“the first test in a package marked with `@pytest.mark.skip`
is now correctly skipped”*) as the culprit, and note the same bug breaks Django setups and
coverage for `src`-layout packages (#6196).

## Root cause

PR #5831 made two relevant changes:

1. `python.py:pytest_collect_file` now matches `python_files + ["__init__.py"]`, so **any**
   `__init__.py` is turned into a `Package` node via `pytest_pycollect_makemodule`.
2. `python.py:Package.collect` begins with an **unconditional** `self._mount_obj_if_needed()`.

Because of (1), `Session._collect` (in `main.py`, the directory-collection branch) creates a
`Package` for *every* directory that merely contains an `__init__.py` and stores it in
`self._pkg_roots`. During `genitems`, that `Package.collect()` runs, and the first line
(`self._mount_obj_if_needed()` → `_getobj` → `_importtestmodule` → `fspath.pyimport`)
**imports the `__init__.py`** — regardless of whether the package contributes any test.
That eager import is the side effect that breaks the build (`assert False`, Django settings,
early-import / coverage issues, etc.).

The eager mount is only actually *needed* when the package does contribute something to
collect: mounting the package object both imports `__init__.py` and, because
`Package._ALLOW_MARKERS` is `True`, copies the package-level `pytestmark` (e.g.
`pytestmark = pytest.mark.skip` in `__init__.py`) into `Package.own_markers`, which is what
makes those markers propagate to the package's tests (test `test_skip_package`). For a
package with no tests there is nothing to import for, so the import is pure (and harmful)
side effect.

## Fix

File changed: `src/_pytest/python.py`, method `Package.collect`.

Instead of importing the package up-front, the mount is **deferred** so it happens only once
the package is known to contribute a collectible node:

- Removed the unconditional `self._mount_obj_if_needed()` from the top of `collect()`.
- Call `self._mount_obj_if_needed()` right before yielding the package's own `__init__.py`
  module (the case where `__init__.py` itself matches `python_files`).
- Call `self._mount_obj_if_needed()` right before yielding each file collected from inside
  the package.

`_mount_obj_if_needed()` is idempotent (it short-circuits once `_obj` is set), so calling it
per yielded node is cheap. The net effect:

- A package that yields **nothing** (e.g. `foobar/` with only an `__init__.py` and no test
  files) is never mounted, so its `__init__.py` is never imported → the regression is gone.
- A package that yields tests still mounts before the first child, so its `__init__.py` is
  imported exactly as before and package-level markers are still collected → `test_skip_package`,
  `test_collect_init_tests`, `test_collect_pkg_init_*` keep passing.
- For broken `__init__.py` files in packages that *do* contain tests, the import error still
  surfaces during `Package.collect()` and is still attributed to the package node (unchanged
  error behaviour).
- For flat `src`-layout packages (`src/mypackage/__init__.py` + modules, no tests of their
  own) the `__init__.py` is no longer imported during collection, addressing the coverage
  symptom mentioned in #6196.

I also added a `changelog/6197.bugfix.rst` newsfragment to match project convention.

The change only reduces the set of `__init__.py` files imported; it never imports anything
that was not already imported before, so it cannot introduce new import side effects.

## Assumptions and rejected alternatives

- **Rejected: remove `+ ["__init__.py"]` from `pytest_collect_file`.** This is the most
  obvious "revert", but `Package` nodes are *only* created through `pytest_collect_file` →
  `pytest_pycollect_makemodule`. Removing it stops `Package` creation entirely, which breaks
  `Test_getinitialnodes.test_pkgfile` (a file collected inside a package whose empty
  `__init__.py` does not match `python_files` must still have a `Package` parent) and the
  `_pkg_roots` machinery in `main.py:Session._collect`. So the hook must keep producing
  `Package` nodes; the problem is the *eager import*, not the node creation.

- **Rejected: fully revert PR #5831.** That would reintroduce #5830 and remove the
  `test_skip_package` behaviour (package-level `pytestmark` propagation). A targeted fix that
  keeps #5830 working while removing the unwanted import is preferable and matches the
  maintainers' stated intent.

- **Rejected: guard the import at the `Session._collect` directory level** (skip creating a
  `Package` for an `__init__.py`-only directory). This requires pre-scanning each directory
  for tests and duplicates logic that `Package.collect()` already performs; deferring the
  mount inside `Package.collect()` is smaller and keeps all package-creation paths
  (directory walk, parent walk for file args, nested sub-packages) working uniformly.

- **Assumption about marker timing.** In this version `skipping.py:pytest_runtest_setup` is
  `@hookimpl(tryfirst=True)` and reads `item.iter_markers("skip")` *before*
  `runner.py:pytest_runtest_setup` runs `SetupState.prepare` (which would mount the package
  via `Package.setup`). Therefore the package's markers must be populated during *collection*.
  The deferred mount still runs during collection (before any test executes) whenever the
  package yields a child, so marker propagation is preserved.

- **Note on the empty `Package`.** `Session._collect` still creates a `Package` node for an
  `__init__.py`-only directory, but with the fix that node collects zero items. Empty
  collectors are invisible in `--collect-only` output (the reporter walks parents of *items*)
  and contribute nothing to the collected count, so behaviour observable to users/tests is
  identical to the package not being collected at all.

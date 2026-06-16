# FVK FINDINGS for pytest-dev__pytest-6197

Status: constructed, not machine-checked. Findings are based on public intent,
source inspection, and proof obligations only; no code or tests were executed.

## F1 - Pre-fix eager package import violates issue intent

Input shape: directory collection of a tree containing `foobar/__init__.py` with
no collectable module below `foobar`.

Observed in base issue: pytest imports `foobar/__init__.py` and reports
`ERROR collecting foobar/__init__.py`.

Expected: pytest may discover `foobar` as a package-shaped directory, but it
must not execute `foobar/__init__.py` unless collection proceeds to a real module
inside that package or configured `python_files` asks to collect the initializer
as a module.

Classification: code bug in the 5.2.3 base behavior.

Resolution status: closed by V1 according to PO1 and PO2. V1 removes
`self._mount_obj_if_needed()` from `Package.collect()`, so package discovery no
longer imports the initializer.

## F2 - V1 audit concern: Package collectors are still created for every package

Input shape: directory traversal sees `__init__.py`, so `pytest_collect_file()`
can still create a `Package` collector because `__init__.py` is included in the
collector pattern list.

Observed in V1 source: the collector is still created; this is deliberate to
preserve package parent chains and direct file collection behavior.

Expected: creating a `Package` collector must be harmless by itself. The import
event must be separated from discovery and delayed until a `Module.collect()`
path exists.

Classification: proof obligation, not an open code bug.

Resolution status: discharged by PO1 and PO2. `Package.collect()` now only scans
and yields child collectors; recursive package-only scans emit no import event.

## F3 - Package-level marks must remain visible to child tests

Input shape: a package `__init__.py` defines `pytestmark =
pytest.mark.skip`, and a sibling `test_*.py` module contains tests.

Observed risk if all package mounting were removed: child `Function` items would
not inherit marks from the package node.

Expected: package parents are mounted before child functions are created.

Classification: compatibility requirement.

Resolution status: discharged by PO3. V1 calls `_mount_package_parents()` at the
start of `Module.collect()`, before `PyCollector.collect()` creates
`Function` items.

## F4 - Configured tests in `__init__.py` must still work

Input shape: `python_files = *.py` and a package initializer contains
`def test_init(): ...`.

Observed risk if `__init__.py` collection were disabled globally: configured
initializer tests would be skipped or parent chains for explicit initializer
paths would break.

Expected: `Package.collect()` still yields `Module(__init__.py)` when
`python_files` matches, and import occurs on that module-collection path.

Classification: compatibility requirement.

Resolution status: discharged by PO4. V1 does not change the
`path_matches_patterns(init_module, python_files)` gate.

## F5 - Public API and plugin compatibility

Input shape: public or plugin code invoking pytest collection hooks or relying
on `Package`/`Module` collector types.

Observed risk: a broader fix could change hook signatures, collector return
types, or `python_files` matching.

Expected: import timing changes should not alter public hook signatures or node
classes.

Classification: compatibility requirement.

Resolution status: discharged by PO5. V1 changes only internal timing inside
existing methods.

## Residual Risks

R1. This FVK model is abstract and constructed, not machine-checked. The exact K
commands are recorded in `PROOF.md`, but were not run.

R2. Third-party `pytest_collect_file` or `pytest_pycollect_makemodule` hooks can
execute arbitrary code while handling `__init__.py`. That is outside the
built-in behavior reported by the issue and is not changed by V1.

R3. Termination of recursive filesystem traversal is not proved here. The proof
is partial correctness: if collection traversal completes, the stated import
event properties hold.

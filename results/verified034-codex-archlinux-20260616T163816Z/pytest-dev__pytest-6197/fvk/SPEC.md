# FVK SPEC for pytest-dev__pytest-6197

Status: constructed, not machine-checked. No tests, Python code, or K tooling
were executed.

## Scope

This FVK pass audits the V1 change in `repo/src/_pytest/python.py`, which moved
package mounting from `Package.collect()` to `Module.collect()`.

The observable under verification is whether collection imports a package
`__init__.py` while traversing a directory. The proof abstracts away unrelated
pytest behavior and keeps the property axis that matters: package discovery may
create collectors, but import events must occur only on module collection paths.

## Intent Spec

I1. Directory collection must not import arbitrary package initializers that are
not needed for collected tests.

Evidence: `benchmark/PROBLEM.md` reports that pytest 5.2.3 "tries to import any
`__init__.py` file under the current directory" and shows `foobar/__init__.py`
raising during collection while only `test_foo.py` should run.

I2. If pytest collects a real Python module inside a package, importing package
parents is allowed and expected. Python imports package initializers while
importing modules inside packages, and pytest must preserve package-level marks
from `__init__.py` for child items.

Evidence: the public hint identifies #5831 as the culprit; the in-repo test
`testing/test_skipping.py::test_skip_package` requires `pytestmark` in
`__init__.py` to skip tests in a sibling test module.

I3. Explicit collection of tests from `__init__.py` remains governed by
`python_files`. A package initializer that matches `python_files` may be
collected as a module; one that does not match should not be imported merely
because its package was discovered.

Evidence: `testing/test_collection.py::test_collect_init_tests` and
`test_collect_pkg_init_only` document `python_files = *.py` behavior for
collecting test functions from `__init__.py`.

I4. Public collector APIs, hook signatures, node classes, and parent-chain shape
must remain compatible. The fix should change import timing, not the external
collector protocol.

Evidence: the issue asks to stop importing unrelated initializers; it does not
request API or collection-tree redesign.

## Public Evidence Ledger

E1. Source: prompt/problem. Quote: "pytest 5.2.3 tries to import any
`__init__.py` file under the current directory." Obligation: no import event for
an unrelated package initializer during normal directory traversal. Status:
encoded in C1 and PO1/PO2.

E2. Source: prompt/problem example. Quote: `echo 'assert False' >
foobar/__init__.py` followed by `ERROR collecting foobar/__init__.py`.
Obligation: a package with no collectable test module must not execute its
initializer. Status: encoded in C1 and Finding F1.

E3. Source: public hint. Quote: "#5831 could be the culprit". Obligation: audit
the eager package-mounting behavior introduced for package marks, not only file
pattern matching. Status: encoded in R1/R2 and Finding F2.

E4. Source: public in-repo test. Quote: `pytestmark = pytest.mark.skip` in
`__init__.py` causes two sibling module tests to be skipped. Obligation: package
marks must be loaded before child `Function` items observe inherited markers.
Status: encoded in C3 and PO3.

E5. Source: public in-repo test. Quote: `python_files = *.py` collects tests
from package `__init__.py`. Obligation: explicit initializer-as-module
collection remains possible when configured. Status: encoded in C4 and PO4.

E6. Source: implementation/API. Evidence: V1 changes only `Module.collect()` and
`Package.collect()` internals. Obligation: no hook signature or public collector
type changes. Status: encoded in C5 and PO5.

## Abstract Model

Events:

- `DiscoverPackage(P)`: pytest creates or traverses a `Package` collector.
- `CollectPackage(P)`: `Package.collect()` scans a package directory.
- `CollectModule(M)`: `Module.collect()` begins for a concrete module.
- `Import(P)`: package initializer `P/__init__.py` is executed.
- `CreateItem(F)`: a test item is created and can read inherited markers.

Predicates:

- `ModuleDesc(P)`: package `P` has a descendant module that pytest will collect
  as a `Module`, including an initializer module when `python_files` matches it.
- `InitMatches(P)`: `P/__init__.py` matches `python_files`.
- `Parents(M)`: package parent chain for module `M`, ordered outermost to
  innermost.

V1 transition rules:

R1. `CollectPackage(P)` scans `P`, yields child collectors, and does not call
`P.obj` or `_mount_obj_if_needed()`.

R2. If `CollectPackage(P)` yields no `Module` descendant, recursive collection
of yielded package collectors performs only R1 transitions and emits no
`Import` events.

R3. If a yielded child is `Module(M)`, `Module.collect()` first calls
`_mount_package_parents()`, which emits `Import(Q)` for each package
`Q in Parents(M)` not already mounted.

R4. `Module.collect()` then imports `M`, parses fixtures, and creates items.
Therefore every `CreateItem(F)` under `M` occurs after package parent imports.

R5. If `InitMatches(P)` is true, `Package.collect()` may yield
`Module(P/__init__.py)`. That import is a module-collection import, not a
package-discovery import.

## Formal Claims in English

C1. No-import for unrelated package: for every package `P`, if `not
ModuleDesc(P)` and `not InitMatches(P)`, then complete recursive collection from
`CollectPackage(P)` reaches completion with no `Import(P)` event and no import
event for any package below `P`.

C2. Non-test files are ignored without mounting: if every descendant of `P` is a
nonmatching file or a package satisfying C1, then collection of `P` emits no
package import events.

C3. Package marks are available: for every module `M` collected under package
chain `Parents(M)`, all packages in `Parents(M)` are mounted before any
`CreateItem` under `M`, so inherited marks from package `__init__.py` are visible
to `Function.__init__` and later `iter_markers()`.

C4. Configured `__init__.py` tests are preserved: if `InitMatches(P)`, then
`CollectPackage(P)` can yield `Module(P/__init__.py)`, and package importing
occurs through `Module.collect()` for that module.

C5. Compatibility frame: V1 preserves hook signatures, collector classes, node
parent chains, duplicate-path handling, and `python_files` matching behavior
outside the import timing described by C1-C4.

## Adequacy Audit

C1 matches I1 and I2: it blocks import during package discovery but does not
forbid imports required by module collection.

C2 strengthens C1 over nested packages and non-test files. This is entailed by
the phrase "any `__init__.py` file under the current directory" and by the
reported `src`/coverage breakage hint.

C3 matches I2 and is needed because removing all package mounting would regress
#5831's package mark behavior.

C4 matches I3 and prevents the proof from overcorrecting by disabling
configured initializer tests.

C5 matches I4. The proof does not rely on changing public APIs or plugin hook
contracts.

No claim depends solely on V1's current behavior. The implementation supplies
the transition shape, while the import/no-import boundary comes from the public
issue and in-repo compatibility evidence.

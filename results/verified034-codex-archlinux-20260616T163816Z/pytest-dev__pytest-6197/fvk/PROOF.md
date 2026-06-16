# FVK PROOF for pytest-dev__pytest-6197

Status: constructed, not machine-checked. No tests, Python code, `kompile`,
`kast`, or `kprove` were executed.

## Machine-check Commands Not Run

These are the commands that would machine-check the abstract model later:

```sh
kompile fvk/mini-pytest-collection.k --backend haskell
kast --backend haskell fvk/pytest-collection-spec.k
kprove fvk/pytest-collection-spec.k
```

Expected result if the abstract claims discharge: `#Top`.

## Proof Summary

The proof separates two states that the regression conflated:

1. discovering a package-shaped directory and creating a `Package` collector;
2. mounting/importing package `__init__.py` so child module items inherit package
   metadata.

The public issue forbids import in state 1 for unrelated packages. Public
compatibility evidence requires import in state 2 when pytest actually collects a
module inside the package.

## Claim C1/C2 - No import for unrelated packages

Initial state: `CollectPackage(P)` with no module descendant and no
`python_files` match for `P/__init__.py`.

V1 transition:

- `Package.collect()` no longer calls `_mount_obj_if_needed()`.
- The collector scans its directory.
- Own `__init__.py` is skipped unless the explicit `python_files` gate yields a
  `Module`.
- Nonmatching files produce no module collector.
- Nested package collectors recursively use the same no-mount transition.

By PO1, the local package-collect step emits no `Import(P)`. By PO2, recursive
package-only children emit no import events. Therefore complete recursive
collection of an unrelated package tree reaches completion with no package
initializer import.

This removes the reported failure mechanism: `foobar/__init__.py` with
`assert False` is not executed when `foobar` contributes no collected module.

## Claim C3 - Package marks are preserved

Initial state: `Module.collect(M)` where `M` has package parents `P1..Pn`.

V1 transition:

- `Module.collect()` first calls `_mount_package_parents()`.
- `_mount_package_parents()` walks `self.listchain()` in outer-to-inner order
  and calls `_mount_obj_if_needed()` on each `Package` parent.
- Only after this step does `Module.collect()` inject setup fixtures, parse
  factories, and call `PyCollector.collect()`.
- `PyCollector.collect()` creates `Function` items.
- `Function.__init__` populates keyword marker names from `iter_markers()`.

Because all package parents are mounted before `Function.__init__`, package
marks copied from `__init__.py` are visible to child test items. This preserves
the #5831 behavior without importing packages that never lead to a module.

## Claim C4 - Configured `__init__.py` modules are preserved

Initial state: `CollectPackage(P)` where `P/__init__.py` matches `python_files`.

V1 transition:

- `Package.collect()` still checks
  `path_matches_patterns(init_module, self.config.getini("python_files"))`.
- If true, it yields `Module(init_module, self)`.
- Import happens when that module's `Module.collect()` path runs, where C3 also
  mounts package parents before item creation.

Therefore configured tests in `__init__.py` still collect.

## Claim C5 - Compatibility frame

V1 changes neither hook signatures nor collector return protocols. `Package`
and `Module` remain the collector classes for package initializers and Python
modules. Duplicate-path handling, ignore hooks, and `python_files` matching are
not part of the changed transition.

## Test Recommendation

No tests were removed or modified. Because this proof is constructed but not
machine-checked, all existing tests should be kept. Useful public or hidden tests
for this fix would cover:

- unrelated `pkg/__init__.py` with an import-time failure and no test modules;
- unrelated package containing only non-test `.py` files;
- nested unrelated packages with no collected modules;
- package `pytestmark` in `__init__.py` applying to sibling test modules;
- `python_files = *.py` collecting tests from `__init__.py`.

## Residual Risk

The proof is partial correctness over an abstract collection model. It does not
prove filesystem traversal termination, py.path behavior, or arbitrary third-
party hook behavior.

# Control notes — review outcome for pytest-dev__pytest-6197

This documents every decision taken during the review, each traced to numbered entries in
`review/FINDINGS.md`. Net result: **V1's logic stands unchanged; only code comments were
clarified.** A refinement was drafted mid-review and then reverted after deeper analysis.

## Summary of the fix being reviewed

`src/_pytest/python.py:Package.collect()` no longer imports a package's `__init__.py`
eagerly. The import (`_mount_obj_if_needed()`) is deferred so it runs only when the package
is about to yield a node to collect. A package with no tests yields nothing and is never
imported — which is exactly the regression in #6197 (and the `src`-layout/coverage symptom
in #6196).

## Decisions

### D1 — Keep the deferred-mount approach (do not revert to eager mount)
**Trace: F1, F3.**
The deferred mount is what fixes the reported repro: `foobar/__init__.py` (no tests) yields
nothing, so it is never imported (F1). It still imports — and collects markers from — a
package that *does* yield a test, before the first yield, which is required for
`test_skip_package` because the skip marker must be on `Package.own_markers` by the time the
`tryfirst` skip check runs during collection-time setup (F3). Kept as-is.

### D2 — Mount before *any* yielded child, including the `init_module` yield (do NOT special-case sub-`Package` nodes)
**Trace: F2, F2a, F2b.**
During the review I suspected V1 still imported nested non-test packages (F2) and drafted a
refinement: `if not isinstance(x, Package): self._mount_obj_if_needed()` — i.e. mount only
before a direct test module, not before a sub-`Package`. Deeper analysis reversed that:

- In the normal directory-collection flow, `Session.collect()` is fully materialised before
  any `genitems` runs and de-duplicates every sub-package's `__init__.py` into the shared
  `_duplicatepaths`; `Package.collect()` then gets `()` for those paths and never yields a
  sub-`Package`. So the refinement would be a **no-op** there, and plain V1 already does not
  import nested non-test packages (F2a).
- The only path where a sub-`Package` *is* yielded by `Package.collect()` is an explicit
  `runpytest("pkg/__init__.py")` argument, where importing `pkg` is the **correct** response
  to an explicit request (and matches original behaviour). The refinement would wrongly
  *skip* importing an explicitly-requested package (F2b).

Therefore the drafted `isinstance` check was **reverted**; V1's unconditional
`self._mount_obj_if_needed()` before each yield is retained.

### D3 — Leave error attribution, empty-package handling, doctest mode, and generator semantics untouched
**Trace: F4, F5, F6, F7.**
Each was reviewed and found already correct under V1: broken `__init__.py` in a real test
package still errors at the package node (F4); a childless `Package` is invisible in output
and counts (F5); `--doctest-modules` collects/imports modules via `DoctestModule`
independently of this change (F6); and per-node `_mount_obj_if_needed()` is idempotent and
safe inside the generator (F7). No code change.

### D4 — No changes to other `Package`-creating call sites
**Trace: F8.**
`Session._collect`'s parent walk and directory branch create `Package` nodes but never call
`Package.collect()` directly, so the only eager-import site was the one V1 already guards.
Nothing else to change.

### D5 — Confirm existing package tests remain green; make no test changes
**Trace: F9.**
`test_collect_init_tests`, `test_collect_pkg_init_only`,
`test_collect_pkg_init_and_file_in_args`, `test_collectignore_via_conftest`,
`test_collect_pyargs_with_testpaths`, and `Test_getinitialnodes.test_pkgfile` were each
traced and produce the same nodes/outcomes under V1. (Test files are not modified.)

### D6 — Clarify comments only (the sole edit made in this round)
**Trace: F2a/F2b, F10.**
The method's two comments were reworded so they describe the *actual* contract — the package
is imported once it is about to yield something to collect — rather than over-claiming. This
is a maintainability improvement consistent with the surrounding style (F10); it does not
change behaviour. (A `changelog/6197.bugfix.rst` newsfragment from V1 is retained.)

## What changed in the source this round
- `src/_pytest/python.py:Package.collect()`: drafted `isinstance(x, Package)` guard added and
  then **reverted** (net zero logic change vs V1); two comments reworded for accuracy.

No other source files were touched. The behaviour of the fix is identical to V1; the review
strengthened the *justification* (the de-duplication argument in F2a) and removed an
unjustified refinement (F2b).

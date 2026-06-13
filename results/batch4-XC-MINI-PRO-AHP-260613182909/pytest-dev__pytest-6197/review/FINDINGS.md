# Code review — V1 fix for pytest-dev__pytest-6197

## What V1 changed

`src/_pytest/python.py:Package.collect()` originally began with an unconditional
`self._mount_obj_if_needed()`, which imports the package's `__init__.py`. V1:

- removed that unconditional call from the top of the method;
- calls `self._mount_obj_if_needed()` immediately before `yield Module(init_module, self)`
  (the case where the package's own `__init__.py` is itself a test module);
- replaced `yield from self._collectfile(path)` with
  `for x in self._collectfile(path): self._mount_obj_if_needed(); yield x`.

Net intent: a package's `__init__.py` is imported only when the package is about to yield
something to collect; a package that collects nothing is never imported.

Findings are numbered; severity in brackets. The review *initially* suspected a real defect
(F2) and a fix was drafted and then reverted after deeper analysis — that reasoning is
recorded under F2/F2a because it is the central question of this review.

---

## F1 — Correctness on the reported repro [PASS]

Repro: `foobar/__init__.py` contains `assert False`, a top-level `test_foo.py`, default
`python_files`.

- `Session._collect` still creates `Package(foobar)` (since `pytest_collect_file` matches
  `+ ["__init__.py"]`) and `genitems` calls `Package(foobar).collect()`.
- `init_module` (`foobar/__init__.py`) does not match `test_*.py`/`*_test.py`, so it is not
  yielded. The only visited file is `foobar/__init__.py`, skipped by the existing
  `if path.basename == "__init__.py" and path.dirpath() == this_path: continue`.
- The loop yields nothing ⇒ `_mount_obj_if_needed()` is never called ⇒ `foobar/__init__.py`
  is never imported ⇒ no `AssertionError`. `test_foo.py` passes.

**V1 fixes the reported case.**

## F2 — Suspected gap: nested non-test packages [INVESTIGATED → NOT A DEFECT]

Initial worry: `pytest_collect_file` is **not** `firstresult` (hookspec.py:205), so
`_collectfile` can return a `Package` for a *sub-package's* `__init__.py`. V1 mounts before
every yielded node, including a sub-`Package`. So for

```
mypackage/__init__.py        # side effect on import
mypackage/subpkg/__init__.py # no tests anywhere
```

it *looked* like `Package(mypackage).collect()` would yield `Package(subpkg)` and import
`mypackage/__init__.py` even though nothing has tests — i.e. V1 would only fully fix the
*leaf* case.

### F2a — Why this does NOT happen in the normal flow [RESOLVED by de-duplication]

In the default directory-collection flow the worry is unfounded, because of ordering +
de-duplication:

1. `_perform_collect` (main.py:463) runs `collect_one_node(self)` which, via
   `pytest_make_collect_report` (runner.py:256), does `list(Session.collect())` — i.e.
   `Session.collect()` is fully materialised **before** any `genitems` runs (main.py:476).
2. `Session._collect`'s directory branch visits the whole tree breadth-first and calls
   `_collectfile(pkginit)` for **every** sub-package directory (main.py:536), adding each
   `__init__.py` to the shared `config.pluginmanager._duplicatepaths` (main.py:591).
3. `Package._collectfile` uses that **same** shared set (python.py:627). So when
   `Package(mypackage).collect()` later runs and reaches `subpkg/__init__.py`, `_collectfile`
   finds it already in `_duplicatepaths` and returns `()` — **no sub-`Package` is yielded**.

Therefore `Package(mypackage).collect()` yields nothing, never mounts, and
`mypackage/__init__.py` is **not** imported. The nested no-test case is already handled by
V1. (When `subpkg` *does* contain a test, importing `mypackage/__init__.py` is unavoidable —
Python imports the parent package when importing the sub-module — so that is not a
regression.)

### F2b — The one path where a sub-`Package` IS yielded [PLAIN V1 IS CORRECT]

The only way `Package.collect()` yields a non-deduplicated sub-`Package` is the explicit
file argument `runpytest("pkg/__init__.py")` (main.py:551-574): the parent walk uses
`handle_dupes=False`, so `subpkg/__init__.py` is not pre-deduplicated, and the special
`__init__.py` branch does `yield next(Package(pkg).collect())`. Here the user **explicitly
asked** to collect `pkg/__init__.py`, so importing `pkg` (plain V1's behaviour, and the
original eager-mount behaviour) is correct.

**Conclusion:** a refinement that skipped mounting before sub-`Package` nodes
(`if not isinstance(x, Package): ...`) was drafted, but it is (a) a no-op in the normal flow
(sub-packages are deduplicated, never yielded), and (b) **wrong** in the explicit-arg flow
(it would refuse to import a package the user explicitly pointed at). It was therefore
**reverted**; V1's "mount before any yield" stands.

## F3 — Package-level marker propagation, direct case [PASS — must preserve]

`test_skip_package` (test_skipping.py:1167): `pytestmark = pytest.mark.skip` in a package
`__init__.py`, tests in a sibling `test_*.py`; both must be skipped. The skip check runs in
`skipping.py:pytest_runtest_setup` (`@hookimpl(tryfirst=True)`), i.e. **before**
`runner.py:pytest_runtest_setup` runs `SetupState.prepare`/`Package.setup` (which would mount
lazily). So `Package.own_markers` must be populated during **collection**.
`Package._ALLOW_MARKERS` is `True` (Package.__init__ calls `FSCollector.__init__`, never
sets it to `False`), so mounting copies the `__init__.py` markers into `own_markers`.

This package has a *direct* test module, so V1 mounts (before yielding it) ⇒ markers
collected ⇒ both tests skipped. **Preserved.** (Verified by grep: `test_skip_package` is the
only package-level `pytestmark` test; every other `pytestmark` hit under `testing/` is class-
or module-level, and none nests packages.)

## F4 — Error attribution for a broken `__init__.py` in a real test package [PASS]

If a package that *does* contain tests has a broken `__init__.py`, V1 still raises inside
`Package.collect()` (the mount happens before the first yielded child), so the failure is
reported as a collection error on the package node — same as the original eager-mount
behaviour. **No change in error behaviour.**

## F5 — Empty `Package` left in the collection tree [PASS / harmless]

`Session._collect` still yields `Package(foobar)`; with V1 it collects zero items.
`TerminalReporter._printcollecteditems` (terminal.py:612) builds output by walking the parent
chain of each *item*, so a childless collector never appears in `--collect-only`; it also
adds 0 to `testscollected`. `collect_one_node` on an empty generator returns a passed report
with an empty result (no error). Observable behaviour equals "package not collected".
**Harmless.**

## F6 — `--doctest-modules` interaction [PASS]

In doctest mode `pytest_collect_file` (not firstresult) also returns a `DoctestModule` for a
`.py` file; `DoctestModule` imports the module itself for doctests. Doctest collection does
not depend on `Package.collect()` mounting the package, and V1 removes no doctest collection.
For a non-test package under `--doctest-modules`, importing its `__init__.py` is the explicit
intent of that flag and still happens via `DoctestModule`. **No doctest regression.**

## F7 — Idempotency / generator semantics of the per-node mount [PASS]

`_mount_obj_if_needed` short-circuits once `_obj` is set, so calling it per yielded node is
cheap and side-effect-free after the first call. `_collectfile` returns an already-realised
list (`()` or the hook result), so iterating it cannot raise mid-stream. Mounting during the
generator is fine: all yields happen during collection (before any test runs), so
`own_markers` is in place for the collection-time skip check (F3).

## F8 — Other paths that create `Package` nodes [PASS]

`Session._collect`'s parent walk (explicit file args) and directory branch create `Package`
nodes via `_collectfile`/`pytest_collect_file` but do **not** call `Package.collect()`
directly (the parent walk only populates `_pkg_roots`/`_node_cache`; the file-arg branch
collects the specific file). So a package's `__init__.py` is imported only through
`Package.collect()` (now guarded) or through Python importing a parent when a real sub-module
is imported. No other eager-import path was missed. **Confirmed.**

## F9 — Existing package/`__init__.py` tests stay green [PASS]

Traced against V1:
- `test_collect_init_tests` (test_collection.py:946): `python_files=*.py` ⇒ `init_module`
  matches ⇒ mount + yield `Module(__init__.py)`, then `test_foo.py` ⇒ mount + yield. 2 items,
  init first. ✓
- `test_collect_pkg_init_only` (1206): no sub-package; default ⇒ nothing yielded ⇒ not
  imported ⇒ "no tests ran"; `*.py` ⇒ init matches ⇒ 1 passed. ✓
- `test_collect_pkg_init_and_file_in_args` (1177): both flows yield the same nodes as before;
  the deliberate duplicate (`test_file` twice) is unaffected. ✓
- `test_collectignore_via_conftest` (1164), `test_collect_pyargs_with_testpaths` (1090),
  `Test_getinitialnodes.test_pkgfile` (643): unaffected — either yield nothing, yield direct
  modules (mount fires), or never call `Package.collect()`. ✓

## F10 — Consistency / minimality [PASS]

The fix reuses existing private helpers (`_mount_obj_if_needed`, `_collectfile`), touches a
single method, preserves the established structure (init-module first, then the breadth-first
visit with `pkg_prefixes`), and changes no public API or hook contract. A `changelog`
newsfragment was added per `changelog/README.rst`.

---

## Verdict

V1 is correct. It fixes the reported regression (F1), preserves the required marker
propagation (F3), error attribution (F4), output (F5), doctest behaviour (F6), and all other
package-creation paths (F8), and keeps the existing package tests green (F9). The one
suspected defect (F2 — importing nested non-test packages) was disproved: the shared
`_duplicatepaths` de-duplication, applied during the fully-materialised `Session.collect()`
before `genitems`, means `Package.collect()` does not re-yield sub-packages in the normal
flow (F2a); the only path that does is an *explicit* `__init__.py` argument, where importing
is correct (F2b). The drafted `isinstance(x, Package)` refinement was reverted. **V1 stands,
with only comment clarifications.**

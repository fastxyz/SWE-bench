# SPEC.md — formal specification of the V1 fix for pytest-dev/pytest#6197

**Target unit:** `Package.collect()` in `repo/src/_pytest/python.py` (lines ~641–680),
plus the helper `PyobjMixin._mount_obj_if_needed()` it calls.

**Mode:** intent-spec (align *intent* ↔ *code* ↔ *formal spec*), partial correctness.

**Status:** specs constructed; proof in [`PROOF.md`](PROOF.md); **not machine-checked**
(no K toolchain in this environment).

---

## 1. Intent (from PROBLEM.md, baseline_notes.md, and the surrounding code)

`Package.collect()` is the collector for a Python *package* (a directory with an
`__init__.py`). Its job is to **yield the collectible child nodes of that package**:

- the package's own `__init__.py` as a `Module`, *iff* `__init__.py` matches the
  `python_files` patterns (so it is itself a test module);
- for every file found by a breadth-first `visit` of the package directory (respecting
  `_recurse`, ignore rules, and skipping files that belong to already-seen
  sub-packages), the nodes produced by `self._collectfile(path)`;
- sub-package directories are *delegated*: their directory is recorded in `pkg_prefixes`
  and their `__init__.py` is yielded as a nested `Package`, which collects its own
  contents later.

The **regression #6197** is a *side effect*, not a wrong return value: pytest 5.2.3
imported **every** `__init__.py` under the rootdir during collection — even packages
that hold no tests — which can fail collection (`assert False`), bypass Django settings,
or corrupt coverage for `src`-layout packages (#6196). The import is performed by
`_mount_obj_if_needed()` (→ `_getobj` → `_importtestmodule` → `fspath.pyimport`), which
V0 called *unconditionally* at the very top of `collect()`.

`_mount_obj_if_needed()` has a second job: because `Package._ALLOW_MARKERS` is `True`,
mounting also copies the package-level `pytestmark` from `__init__.py` into
`Package.own_markers`, which is how those markers propagate to the package's tests
(test `test_skip_package`). In this pytest version the skip check runs at
`pytest_runtest_setup` with `tryfirst=True`, **before** `Package.setup()` would mount
the object — so the markers must be populated **during collection**.

So the fix must satisfy two opposing pulls simultaneously:

- **(Safety)** do *not* import `__init__.py` for a package that contributes nothing;
- **(Markers)** *do* import it (populating `own_markers`) before the first test of a
  package that *does* contribute, since that must happen at collection time.

## 2. Contract for `Package.collect()`

Let `mounted ≜ (self._obj is not None)` (true once `_mount_obj_if_needed()` has run; the
**import of `__init__.py` is the side effect of the first** `False→True` transition) and
let `yielded ≜` the number of nodes the generator has produced.

**Precondition.** `self` is a `Package` whose `self.fspath` is the package's
`__init__.py`; `this_path = self.fspath.dirpath()` is the package directory; `config`,
`session`, `_norecursepatterns` are initialised. No precondition on the file tree.

**Functional postcondition (behaviour-preservation).** The *multiset of yielded nodes*
is exactly as specified in §1 — and is **identical to V0's**, because nothing in the
collection logic (`visit`, `_recurse`, `_collectfile`, `pkg_prefixes`) reads
`self._obj` or `self.own_markers`. The fix changes *when/whether* the side effect runs,
never *what* is yielded.

**Side-effect postcondition (the property the fix establishes).**

> **P1 (no spurious import / safety):** `mounted ⇒ yielded ≥ 1`.
> Equivalently `yielded = 0 ⇒ ¬mounted`: a package that yields nothing never imports
> its `__init__.py`.
>
> **P2 (markers ready):** `yielded ≥ 1 ⇒ mounted`, and the mount happens **before the
> first `yield`**. Since all collection precedes all test execution, `own_markers` is
> populated before any descendant test's skip check.
>
> Together: **`mounted ⟺ yielded ≥ 1`**, with mount ordered before the first yield.

## 3. Loop specification (the `for path in this_path.visit(...)` loop)

**Abstraction.** Collapse the method to its side-effect skeleton: a counting loop that,
for each of the `N` nodes the method yields, performs `_mount_obj_if_needed(); yield`.
`N = (init-module yielded ? 1 : 0) + Σ_path len(self._collectfile(path))`. Every other
branch (skip/`continue`, the `pkg_prefixes.add` directory branch, non-collectible files
for which `_collectfile` returns empty) contributes `0` to `N` and `0` mounts. See
[`package_collect.k`](package_collect.k) for the faithfulness argument.

**Loop invariant** (held before/after every step of the counting loop):

```
mounted ⟺ yielded ≥ 1        and   yielded = i   and   mounted ∈ {0,1}
```

where `i` is the number of nodes processed so far. This is the `(LOOP)` circularity in
[`package_collect-spec.k`](package_collect-spec.k): from a generic `(mounted=M,
yielded=Y, i=I)` with side condition `I ≤ N`, the loop reaches `(yielded = Y+(N−I), i =
N, mounted = M ∨ (I<N))`.

## 4. Side conditions (must hold; discharged in PROOF.md)

- **SC1** `0 ≤ I ≤ N` on every reachable loop state (the counter never overshoots).
- **SC2** `mounted ∈ {0,1}` is preserved (the body only ever *sets* it to `1`).
- **SC3** the mount statement textually precedes the corresponding `yield` in both the
  init-module branch and the per-file branch (a syntactic obligation on the code, not an
  arithmetic VC — see PROOF.md §“guardedness/ordering”).

## 5. What is intentionally *out of scope*

- **Termination** of `visit` / the loop (partial correctness only; the file tree is
  finite in practice — recommendation, not proved).
- The **functional correctness of which files match `python_files`**, the dedup logic,
  and `_recurse` ignore rules — unchanged by the fix and inherited from V0.
- The exact import mechanics of `fspath.pyimport` — treated as an opaque side-effecting
  operation guarded by `mounted`.

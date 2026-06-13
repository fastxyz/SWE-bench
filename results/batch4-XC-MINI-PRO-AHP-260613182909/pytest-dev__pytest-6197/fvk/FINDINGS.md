# FINDINGS.md — pytest-dev/pytest#6197 (V1 audit)

Plain-language findings from writing the spec ([`SPEC.md`](SPEC.md)) and constructing the
proof ([`PROOF.md`](PROOF.md)). Format: `input → observed vs expected`. Findings are
advisory; none of them block. The headline result: **V1 satisfies the safety property
`mounted ⟺ yielded ≥ 1` and is confirmed; one non-minimality residual (F2) is documented
but deliberately not fixed.**

---

## F1 — (root cause, FIXED by V1) V0 imported every `__init__.py` unconditionally

- **input:** a directory `foobar/` containing only `foobar/__init__.py` with side effects
  (`assert False`, Django settings, etc.) and a separate top-level `test_foo.py`; run
  `pytest`.
- **observed (V0):** `Package.collect()` began with an *unconditional*
  `self._mount_obj_if_needed()`, importing `foobar/__init__.py` even though the package
  yields nothing → `ERROR collecting foobar/__init__.py` (`assert False`).
- **expected:** `foobar/__init__.py` is not imported; `test_foo.py` passes → `1 passed`.
- **status:** **fixed.** V1 makes the mount conditional on yielding ≥ 1 node. Formalised
  as the safety corollary of `(COLLECT)`: `N = 0 ⇒ mounted = 0`.
- **classification:** code bug (unwanted side effect) — resolved.

## F2 — (RESIDUAL, not fixed) the import condition is “yields ≥ 1 node”, which over-approximates “has ≥ 1 *descendant test*”

- **input:** `pkg/__init__.py` with a side effect, `pkg/sub/__init__.py`, and **no test
  files anywhere** under `pkg/` (an empty sub-package).
- **observed (V1):** `Package(pkg).collect()` yields the nested `Package(sub)` node, and
  the V1 code mounts *before every yield* — including before yielding a nested `Package`.
  So `pkg/__init__.py` **is still imported**, even though `pkg` ultimately collects no
  tests. (`sub/__init__.py` itself is *not* imported, because `Package(sub).collect()`
  yields nothing.)
- **expected (ideal):** import `pkg/__init__.py` only if some test exists *below* `pkg`.
- **why V1 does this on purpose:** the precise condition “has a descendant test” is not
  knowable at the moment `Package(sub)` is yielded (its `collect()` runs later), so V1
  uses the **sound over-approximation** “yields ≥ 1 node”. This never *misses* a needed
  import, so it preserves marker propagation to nested sub-packages (a `pytestmark` on
  `pkg/__init__.py` must still reach tests in `pkg/sub/…`). The cheaper alternative
  “mount only before non-`Package` yields” would *under*-import and **break** that nested
  marker propagation — trading a harmless non-minimality for a real correctness
  regression.
- **status:** **accepted residual** for #6197. The reported bug (F1) and the common
  `src`-layout case are flat (no sub-package), so they are fully fixed; this residual is
  rarer and is a *sub-optimality*, not a soundness violation. Tracked with an
  UltimatePowers question in [`ITERATION_GUIDANCE.md`](ITERATION_GUIDANCE.md) (G1).
- **classification:** underspecified intent / spec-precision gap (not a regression).

## F3 — (POSITIVE) the fix relies on `_mount_obj_if_needed()` idempotency, which holds

- **input:** a package whose `visit` yields several files; the V1 loop calls
  `self._mount_obj_if_needed()` once per yielded node.
- **observed/expected:** `_mount_obj_if_needed()` guards on `getattr(self, "_obj", None)
  is None`; `_getobj()` → `_importtestmodule()` returns a module object (never `None`),
  so after the first call `_obj` is set and every later call is a no-op. Hence the
  `__init__.py` is imported **at most once** and `own_markers` is extended **once**.
- **status:** confirmed; the spec models the body’s `mounted = 1` as idempotent (`SC2`).
- **classification:** safety precondition satisfied.

## F4 — (MINOR) side-effect ordering differs from V0 on the error path only

- **input:** `pkg/` whose `__init__.py` raises on import (e.g. `assert False`) **and**
  which also contains a real test file (so the package *does* contribute).
- **observed (V1):** the loop calls `self._collectfile(first_file)` (whose `handle_dupes`
  branch adds `first_file` to `pluginmanager._duplicatepaths`) **before** the mount
  raises. V0 raised at the top of `collect()`, before any `_collectfile`, so the file was
  not yet recorded as a duplicate.
- **expected:** both versions report a package-level collection error and collect nothing
  from `pkg/`; that outcome is identical. The only difference is an extra entry in the
  dedup set, reachable only if the *same* file is also requested through another argument
  while the package is erroring.
- **status:** negligible (error path, not observable in normal runs); documented, not
  fixed. Marker/error attribution is otherwise unchanged: the mount still raises *inside*
  `collect()`, so the failure is still attributed to the `Package` node.
- **classification:** benign behavioural delta on an exceptional path.

## F5 — (POSITIVE) marker-timing soundness is preserved (`test_skip_package`)

- **input:** `__init__.py` with `pytestmark = pytest.mark.skip` plus a test module in the
  same package; expect both tests skipped.
- **observed/expected:** V1 mounts the package object **before the first yielded node**
  (init-module branch or per-file branch). Mounting populates `Package.own_markers` with
  the `skip` mark. Because *all collection precedes all `runtest`*, `own_markers` is ready
  before `skipping.pytest_runtest_setup` (`tryfirst=True`) reads `iter_markers("skip")`.
  → both tests skipped. Formalised as the marker corollary of `(COLLECT)`:
  `N ≥ 1 ⇒ mounted`.
- **status:** confirmed; this is the constraint that rules out the naive “just delete the
  mount” fix and justifies the *conditional* mount.
- **classification:** correctness-preserving design constraint, satisfied.

---

## Spec-difficulty signal (benefit #2)

Writing a **clean** side-effect spec was *possible* and yielded the tidy invariant
`mounted ⟺ yielded ≥ 1`. The one place the spec resisted being perfectly tight is F2:
the honest invariant is over the *yielded nodes*, and only an over-approximation of the
truly-intended “has a descendant test”. Per the kit’s rule (“spec-difficulty is a bug
signal”), that residual is reported explicitly rather than papered over — but here it is
a *precision* gap with a sound, marker-correct resolution, not a hidden bug.

## Proof-derived findings (from `/verify`)

- The `(LOOP)` circularity needed the side condition **`I ≤ N`** (SC1) and
  **`mounted ∈ {0,1}`** (SC2). Both are *established by the entry state* of `(COLLECT)`
  (`i = 0 ≤ N`, `mounted = 0`) and *preserved* by the body — i.e. they are not silent
  assumptions on external input but invariants the code maintains. No missing
  precondition on the caller surfaced.
- All verification conditions are **linear arithmetic + boolean** (no nonlinear/`/Int`
  products, unlike the `sum` example), so no `[simplification]` lemmas are required; Z3
  discharges them. This is *evidence the fix is simple*: a clean, low-order contract.

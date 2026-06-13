# FVK notes — audit of the V1 fix for pytest-dev/pytest#6197

**Outcome: V1 stands unchanged.** The Formal Verification Kit audit confirmed that V1
satisfies its specification; it surfaced no correctness bug, and the one residual it
surfaced (F2) must *not* be "fixed" because doing so would introduce a real regression.
This note justifies that conclusion (and every non-change) by tracing to the FVK
artifacts under `fvk/`.

## What was formalized

I specified the audited unit — `Package.collect()` in
`repo/src/_pytest/python.py` and the helper `_mount_obj_if_needed()` — in
[`fvk/SPEC.md`](../fvk/SPEC.md). The fix is about a **side effect** (importing
`__init__.py`), not a return value, so the central contract is the side-effect invariant

> **`mounted ⟺ yielded ≥ 1`**, with the mount ordered before the first `yield`,

abstracted to a single counting loop and written as the K claims `(LOOP)` and
`(COLLECT)` in [`fvk/package_collect.k`](../fvk/package_collect.k) /
[`fvk/package_collect-spec.k`](../fvk/package_collect-spec.k), proved in
[`fvk/PROOF.md`](../fvk/PROOF.md), with the obligation ledger in
[`fvk/PROOF_OBLIGATIONS.md`](../fvk/PROOF_OBLIGATIONS.md).

## Decision 1 — keep the deferred-mount design (no revert, no redesign)

**Traces to:** F1, O-B1, O-C1–O-C3.

The audit re-derived, from the spec, the two opposing requirements the fix must meet:
**(safety)** never import a no-test package's `__init__.py` — finding **F1**, obligation
**O-B1**; and **(markers)** still import it before the first test of a package that *does*
contribute, because in this pytest version the skip check (`skipping.pytest_runtest_setup`,
`tryfirst=True`) reads `iter_markers` *before* `Package.setup()` would mount the object —
finding **F5**, obligations **O-C1–O-C3**. `(COLLECT)`'s two corollaries discharge exactly
these (`N=0 ⇒ ¬mounted`; `N≥1 ⇒ mounted`, ordered by **O-B2**). This is precisely why the
naive alternative "just delete the mount" is wrong (it fails O-C1), and why a full revert
of #5831 is wrong (it reintroduces #5830 / drops `test_skip_package`). The conditional,
ordered mount is the design the obligations demand — V1 already implements it, so it is
kept.

## Decision 2 — keep the exact code form (per-`x` mount), did **not** apply the cosmetic refactor I considered

**Traces to:** O-A1, O-A2, F3, and the §0 abstraction in PROOF.md.

I considered refactoring the loop body from

```python
for x in self._collectfile(path):
    self._mount_obj_if_needed()
    yield x
```

to `collected = self._collectfile(path); if collected: self._mount_obj_if_needed(); yield
from collected`. I **rejected** it for three reasons, all grounded in the artifacts:

1. **Robustness (F3).** The per-`x` form mounts *iff at least one node is actually
   yielded*, regardless of whether `_collectfile` returns a list, tuple, or (hypothetically
   in future) a lazy generator. The `if collected:` form would mount on a truthy-but-empty
   generator. The per-`x` form is the one that literally realizes the proved invariant
   "mount iff yielded ≥ 1" (O-B1/O-C1).
2. **Faithfulness to the proof.** The per-`x` loop *is* the counting loop modelled in
   `package_collect.k` (`while … { mounted = 1 ; yielded = yielded + 1 ; … }`); the proof
   in PROOF.md §2–§3 is constructed against exactly that shape. Keeping the code identical
   to the verified model maximizes the value of the (constructed) proof.
3. **Minimal risk.** O-A1/O-A2 already show the yielded-node multiset and order are
   unchanged from V0; a behavior-neutral cosmetic edit only adds risk without changing any
   discharged obligation.

So the code is left byte-for-byte as V1.

## Decision 3 — do **not** tighten the import condition (leave residual F2)

**Traces to:** F2, O-F2, ITERATION_GUIDANCE G1.

The proof made explicit (PROOF.md §5) that the contract is over `yielded ≥ 1`, and that
`yielded` counts **nested `Package` nodes**. Hence a package whose only content is an
*empty* sub-package still imports its own `__init__.py` (finding **F2**). This is a
non-minimality, not a soundness violation: it never *misses* an import, so nested marker
propagation (O-C1 for `pkg/__init__.py` → tests in `pkg/sub/…`) is preserved.

I deliberately did **not** change the code to chase the tighter "import iff a *descendant
test* exists":

- The precise condition is **not locally decidable** at the point `Package(sub)` is
  yielded (its `collect()` runs later) — O-F2.
- The only cheap local proxy ("mount only before non-`Package` yields") **under-imports**
  and would **break O-C1** for nested packages — i.e. it fixes a harmless non-minimality
  by introducing a real correctness regression. Rejected.
- F2 is outside the reported bug: #6197's repro and the common `src`-layout case are
  *flat* (no sub-package), and the safety corollary fully fixes those.

The proper path for F2 is captured as **G1** in
[`fvk/ITERATION_GUIDANCE.md`](../fvk/ITERATION_GUIDANCE.md) (with an UltimatePowers
question and a nested-model re-verification plan), and likely belongs with #6196, not
#6197.

## Decision 4 — no change for the error-path dedup ordering (F4)

**Traces to:** F4, G2. On a broken-`__init__` package that *also* has tests, V1 records
the first file in `_duplicatepaths` before the mount raises, whereas V0 raised earlier.
The observable outcome (package-level collection error, nothing collected from it) is
identical; the delta is only reachable on an exceptional path and is not observable in
normal runs. Aligning it would require mounting before knowing the path collects anything
(impossible), so no change is made.

## Decision 5 — no test changes; machine-check gate honored

**Traces to:** PROOF.md §6, G4. The proof is of a side-effect invariant, so it subsumes
essentially no existing test: the redundancy set is **empty** and **all** visible tests
are kept (notably `test_skip_package`, the regression guard for O-C1). Per the honesty
gate, removals (here: none) would be conditioned on running the emitted `kompile`/`kprove`
commands; everything is labeled **constructed, not machine-checked**. (Test files were not
touched, per the task constraints, regardless.)

## Residual risk (unchanged from V1, now explicit)

Partial correctness only (termination of `visit`/the loop not proved — O-F1/G3); trusted
base = the §0 abstraction adequacy + the reachability metatheory/`kprove` + the Z3 oracle
+ treating `_mount_obj_if_needed`/`pyimport` as an opaque guarded side effect; and the
"constructed, not machine-checked" caveat. None of these alters the conclusion that V1
correctly fixes #6197.

# ITERATION_GUIDANCE.md — pytest-dev/pytest#6197

Actionable feedback for the next generate→formalize→verify pass. Each item ties to a
finding ([`FINDINGS.md`](FINDINGS.md)) and/or an obligation
([`PROOF_OBLIGATIONS.md`](PROOF_OBLIGATIONS.md)).

**Overall verdict:** V1 is **confirmed** — it discharges the safety obligation O-B1 and
the marker obligations O-C1–O-C3, with no undischargeable VC (no correctness bug). One
deliberate residual (F2 / O-F2) remains and is documented below, not fixed.

---

## G1 — (from F2 / O-F2) tighten "import iff yields a node" → "import iff a descendant test exists"

- **Evidence:** `(COLLECT)` proves `mounted ⟺ yielded ≥ 1`, and `yielded` counts nested
  `Package` nodes (PROOF §5). A `pkg/` whose only content is an empty sub-package still
  imports `pkg/__init__.py`.
- **Classification:** underspecified intent / spec-precision gap (sound over-approx, not a
  bug).
- **UltimatePowers question:** *“When a package has no direct tests but contains a
  sub-package, should the outer package’s `__init__.py` be imported during collection
  (a) always when it has any sub-package [V1], (b) only if some test exists anywhere
  below it, or (c) never until a test under it is actually imported?”* The answer
  determines whether tightening is wanted at all.
- **Why not done in this pass:** the precise condition is **not locally decidable** — at
  the moment `Package(sub)` is yielded, `Package(sub).collect()` has not run, so whether
  a descendant test exists is unknown. The cheap local proxy (“mount only before
  non-`Package` yields”) **under-imports** and breaks **O-C1 for nested packages**: a
  `pytestmark` on `pkg/__init__.py` would stop reaching tests in `pkg/sub/…`. That trades
  a harmless non-minimality for a real correctness regression — rejected.
- **Recommended next change (only if G1’s answer is (b)/(c)):** make a nested
  `Package`'s mount also mount its parent `Package` chain (so the parent's `own_markers`
  are populated lazily when, and only when, a descendant actually contributes), then drop
  the parent’s mount-before-yielding-a-`Package`. This is a larger, separately-verified
  change; re-run `/formalize` with a nested model (outer loop whose body invokes the inner
  `(LOOP)` as a lemma) to re-establish O-C1 before adopting it. Likely belongs with #6196
  rather than #6197.

## G2 — (from F4) optional: align the error-path dedup ordering with V0

- **Evidence:** F4 — on a *broken-`__init__` package that also has tests*, V1 records the
  first file in `_duplicatepaths` before the mount raises; V0 did not.
- **Classification:** benign behavioural delta on an exceptional path.
- **Recommended change (low priority):** none required. If exact parity is desired, mount
  *before* iterating that path’s `_collectfile` — but that is impossible without first
  knowing the path collects something, so it is not worth the contortion. Leave as-is.
- **Tests:** none needed; not observable in normal runs.

## G3 — (from O-F1) termination is a recommendation, not proved

- **Evidence:** partial-correctness default; `this_path.visit(...)` and the loop are not
  proved to terminate.
- **Classification:** termination/performance gap.
- **Recommended next step (only if total correctness is requested):** add a decreasing
  measure `N − i` (≥ 0, strictly decreasing per iteration) to `(LOOP)` and discharge it
  alongside O-D2/O-D3. In practice the file tree is finite, so this is informational.
- **Tests:** keep any integration/perf tests; the proof says nothing about them.

## G4 — machine-check before any test pruning

- **Evidence:** PROOF §6 recommends **no** test removals (a side-effect bugfix subsumes
  little). Even so, honor the honesty gate.
- **Recommended step:** run the `kompile`/`kprove` commands in PROOF §8; only after
  `#Top` would the (here: empty) redundancy set be safe to act on. Until then keep all
  tests, especially `test_skip_package` (the regression guard for O-C1).

---

## Next-iteration checklist

1. Decide G1 via the UltimatePowers question; if tightening is wanted, route it to a
   nested-model re-verification (and probably to #6196).
2. Keep V1 as the #6197 fix — safety (O-B1) and markers (O-C1–O-C3) are established.
3. Leave G2/G3 as documented, no code change.
4. Machine-check (G4) to upgrade "constructed" → "verified"; no tests to drop regardless.

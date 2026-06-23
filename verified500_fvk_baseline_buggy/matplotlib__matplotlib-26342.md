# matplotlib__matplotlib-26342

## Summary

**Severity:** Medium — baseline's new public `ContourSet.set_paths()` replaces the
primary `_paths` store but leaves the derived `_old_style_split_collections` cache
in place, so any later consumer that reads that cache observes stale geometry.

Baseline and FVK both passed the official SWE-bench evaluation for this issue, with
**different** patches. The FVK patch adds one missing step the baseline omitted:
invalidating the old-style split-collection cache before swapping `_paths`. The
defect is a residual frame-condition gap — baseline updated the value the issue
named but not the derived state that depends on it — and FVK located it by
formalizing the setter as a state transition and discharging an explicit derived-cache
obligation, not by running a test.

| Arm | `set_paths()` invalidates derived old-style cache | Resolved |
|---|---|---|
| baseline | no — `_paths` replaced, cache left present | no |
| gold (human oracle) | not available (non-curated) | — |
| **fvk** | yes — cache deleted before `_paths` swap | **yes** |

## 1. The issue and the real defect

The issue asks for a public `ContourSet.set_paths(paths)` so that users can replace
the contour path sequence through a setter instead of the in-place workaround
`paths = cs.get_paths(); paths[:] = transformed_paths`
([`prompts/fvk.md`](../results/verified029-codex-archlinux-20260616T111534Z/matplotlib__matplotlib-26342/prompts/fvk.md#L5),
intent reconstructed in
[`PUBLIC_EVIDENCE_LEDGER.md` E1–E3](../results/verified029-codex-archlinux-20260616T111534Z/matplotlib__matplotlib-26342/fvk/PUBLIC_EVIDENCE_LEDGER.md#L5)).

`ContourSet` subclasses `matplotlib.collections.Collection`, whose `set_paths`
raises `NotImplementedError`, even though `Collection.get_paths` already returns the
`ContourSet._paths` attribute. So before any fix, the public setter call simply
fails on an in-domain input
([`baseline_notes.md`](../results/verified029-codex-archlinux-20260616T111534Z/matplotlib__matplotlib-26342/reports/baseline_notes.md#L5)).

The non-obvious part is that `_paths` is not the only state derived from the contour
geometry. `ContourSet` also materializes `_old_style_split_collections`, a cache of
old-style split path views used by the deprecated `collections`/`allsegs`/`allkinds`
accessors. The existing contour-labeling code already treats that cache as derived
state: `_split_path_and_get_label_rotation` deletes it before mutating `_paths`
([`PUBLIC_EVIDENCE_LEDGER.md` E6](../results/verified029-codex-archlinux-20260616T111534Z/matplotlib__matplotlib-26342/fvk/PUBLIC_EVIDENCE_LEDGER.md#L10)).
A setter that swaps `_paths` without invalidating that cache leaves a window where
the cache exposes path views derived from the **previous** `_paths` — stale geometry.

## 2. Baseline's fix — and where it stopped

[Baseline](../results/verified029-codex-archlinux-20260616T111534Z/matplotlib__matplotlib-26342/solutions/solution_baseline.patch)
added a scoped `ContourSet.set_paths` that does exactly what the issue's workaround
did — assign the new sequence and mark the artist stale:

```python
def set_paths(self, paths):
    self._paths = paths
    self.stale = True
```

Baseline was not careless. Its notes show a deliberate, correct scoping decision: it
considered the alternative of editing the base `Collection.set_paths` to assign
`_paths` generically and **rejected it** because sibling collection subclasses have
specialized path-construction APIs that a base-class change would disturb:

> *"I considered changing `Collection.set_paths` to assign `self._paths` generically.
> I rejected that because several collection subclasses have specialized path
> construction APIs, so changing the base class would broaden behavior beyond the
> reported `ContourSet` issue."*
> — [`baseline_notes.md`](../results/verified029-codex-archlinux-20260616T111534Z/matplotlib__matplotlib-26342/reports/baseline_notes.md#L26)

That reasoning is sound for the compatibility boundary. Where it stopped is the
**frame condition**: baseline modeled `set_paths` as "replace the value the issue
named (`_paths`) and mark stale" and never asked which other state is *derived from*
`_paths` and therefore co-invalidated. The unmet obligation is exactly the
derived-cache invalidation that the existing contour code already performs on its own
mutation path.

## 3. How FVK formally captured the gap

FVK started from an intent spec, not the symptom, and one required-behavior item
reaches past the value the issue literally named to the state derived from it:

> **6.** *Existing contour path-cache views derived from `_paths` must not be treated
> as authoritative after `_paths` is replaced.*
> — [`INTENT_SPEC.md`](../results/verified029-codex-archlinux-20260616T111534Z/matplotlib__matplotlib-26342/fvk/INTENT_SPEC.md#L17)

That intent is pinned to a concrete code fact found by **source audit** of the
existing contour module — not to any reported test:

> **E6 (implementation):** *`_split_path_and_get_label_rotation` deletes
> `_old_style_split_collections` before mutating `_paths`* → *cached old-style
> collections are derived from `_paths` and should be invalidated when `_paths`
> changes.*
> — [`PUBLIC_EVIDENCE_LEDGER.md`](../results/verified029-codex-archlinux-20260616T111534Z/matplotlib__matplotlib-26342/fvk/PUBLIC_EVIDENCE_LEDGER.md#L10)

which is discharged into an explicit proof obligation that the setter must satisfy
for **both** cache states:

> **PO3 — Derived cache invalidation.** *For both old-style cache states, absent and
> present, executing `set_paths(NEW)` leaves the cache absent.*
> — [`PROOF_OBLIGATIONS.md`](../results/verified029-codex-archlinux-20260616T111534Z/matplotlib__matplotlib-26342/fvk/PROOF_OBLIGATIONS.md#L19)

This is the crux of FVK's value here: the residual bug was located by **reasoning
about the state transition**, not by observation. The issue says "replace the paths";
FVK lifts that to "leave the contour path state, the stale flag, *and every cache
derived from the path state* in a consistent post-state", and the audit fact E6 shows
the old-style cache is one such derived state that the in-domain code itself already
invalidates elsewhere. The adequacy obligation makes the discriminator explicit: a
model where the cache stays present for an initially-present cache **fails PO3, so the
model observes the V1 (= baseline) defect**
([`PROOF_OBLIGATIONS.md` PO6](../results/verified029-codex-archlinux-20260616T111534Z/matplotlib__matplotlib-26342/fvk/PROOF_OBLIGATIONS.md#L40)).

## 4. From formal output to the fix

The FVK arm treats the baseline patch as its own V1, audits it against the spec, and
the artifacts record the exact step where the formalism changed the patch.

- **V1** (= baseline) added `set_paths` that swaps `_paths` and sets `stale` only.
- The completeness audit against the spec raised a finding:

  > **F2 — V1 missed old-style cache invalidation.** *Observed in V1: `_paths` is
  > replaced and `stale` is set, but `_old_style_split_collections` remains present
  > and can continue to expose path views derived from the previous `_paths`. …
  > Classification: code bug in V1 / stale derived state.*
  > — [`FINDINGS.md`](../results/verified029-codex-archlinux-20260616T111534Z/matplotlib__matplotlib-26342/fvk/FINDINGS.md#L20)

- The iteration guidance turned the finding into an instruction for the V2 source:

  > *"Keep the scoped `ContourSet.set_paths` implementation and the V2 cache
  > invalidation."*
  > — [`ITERATION_GUIDANCE.md`](../results/verified029-codex-archlinux-20260616T111534Z/matplotlib__matplotlib-26342/fvk/ITERATION_GUIDANCE.md#L7)

- The decision log records the resulting code change and traces it back to F2/PO3:

  > **2. Revised V1 to invalidate `_old_style_split_collections` before replacing
  > `_paths`.** *Trace: `fvk/FINDINGS.md` F2 records that V1 left derived old-style
  > path cache state present … Obligation: `fvk/PROOF_OBLIGATIONS.md` PO3 requires
  > the cache to be absent after `set_paths` for both initially-present and
  > initially-absent cache states.*
  > — [`fvk_notes.md`](../results/verified029-codex-archlinux-20260616T111534Z/matplotlib__matplotlib-26342/reports/fvk_notes.md#L14)

The causal chain is fully on the record:

```
INTENT_SPEC item 6  ->  E6 (code audit: existing code invalidates the cache before mutating _paths)
                    ->  PO3 (obligation: cache absent after set_paths, both cache states)
                    ->  F2  (V1 audit: baseline leaves the cache present)
                    ->  ITERATION_GUIDANCE / fvk_notes decision 2  ->  V2 patch
```

The resulting
[V2 patch](../results/verified029-codex-archlinux-20260616T111534Z/matplotlib__matplotlib-26342/solutions/solution_fvk.patch)
adds the missing invalidation, matching the existing contour-labeling pattern:

```python
def set_paths(self, paths):
    if hasattr(self, "_old_style_split_collections"):
        del self._old_style_split_collections  # Invalidate them.
    self._paths = paths
    self.stale = True
```

The `V1 -> V2` transition was driven by **finding F2 / obligation PO3**, **not** by a
new failing test — the run had no execution environment and was forbidden from editing
or running tests
([`prompts/fvk.md`](../results/verified029-codex-archlinux-20260616T111534Z/matplotlib__matplotlib-26342/prompts/fvk.md#L26)).

## 5. Verification

**Evidence tier: Tier 3 — source-and-artifact reviewed; not executed.** This instance
is non-curated: there is no harness RED/GREEN proof bundle and no gold patch on disk,
and the run itself carried no execution environment, so no behavioral demonstration was
produced.

What was inspected directly:

- The two patches differ by exactly the cache-invalidation guard
  ([baseline](../results/verified029-codex-archlinux-20260616T111534Z/matplotlib__matplotlib-26342/solutions/solution_baseline.patch)
  vs
  [fvk](../results/verified029-codex-archlinux-20260616T111534Z/matplotlib__matplotlib-26342/solutions/solution_fvk.patch));
  the FVK delta is the two lines that `del self._old_style_split_collections` when
  present.
- The fix mirrors an **already-existing** invalidation in the same module — the
  contour-labeling path deletes the same cache before mutating `_paths`
  ([`PUBLIC_EVIDENCE_LEDGER.md` E6](../results/verified029-codex-archlinux-20260616T111534Z/matplotlib__matplotlib-26342/fvk/PUBLIC_EVIDENCE_LEDGER.md#L10)),
  so the repair is a consistency fix against the module's own established pattern, not
  a novel behavior.
- The compatibility audit confirms the change stays scoped to `ContourSet`/
  `QuadContourSet`/`TriContourSet` and touches no base `Collection` behavior, and that
  the deprecated `collections`/`allsegs`/`allkinds` accessors are exactly the
  consumers of the now-invalidated cache
  ([`PUBLIC_COMPATIBILITY_AUDIT.md`](../results/verified029-codex-archlinux-20260616T111534Z/matplotlib__matplotlib-26342/fvk/PUBLIC_COMPATIBILITY_AUDIT.md#L24)).
- The spec audit marks the derived-cache obligation as the one item V1 omitted and V2
  satisfies
  ([`SPEC_AUDIT.md`](../results/verified029-codex-archlinux-20260616T111534Z/matplotlib__matplotlib-26342/fvk/SPEC_AUDIT.md#L8)).

Both arms passed the official SWE-bench evaluation, so the hidden test suite does not
exercise the stale-cache path; the FVK fix is therefore a correctness improvement
**beyond** what the benchmark's own gates measure.

## 6. Boundaries & honesty

- **Severity: Medium.** A public setter appears to succeed and updates the primary
  geometry, but the deprecated old-style accessors can subsequently return stale path
  views derived from the previous `_paths`. The trigger is **narrow** — it requires
  the deprecated `_old_style_split_collections` cache to have been materialized (via
  legacy `collections`/`allsegs`/`allkinds` access) before `set_paths` is called — so
  it is not High; but the failure is a silent wrong-geometry read on a public API path,
  not a cosmetic or hard-to-reach edge, so it is not Low.
- **Proof status: constructed, not machine-checked.** The K artifacts
  ([`mini-python-contour-set.k`](../results/verified029-codex-archlinux-20260616T111534Z/matplotlib__matplotlib-26342/fvk/mini-python-contour-set.k),
  [`contour-set-set-paths-spec.k`](../results/verified029-codex-archlinux-20260616T111534Z/matplotlib__matplotlib-26342/fvk/contour-set-set-paths-spec.k))
  and the `kompile`/`kprove` commands were **written but never run** — the proof
  document says so explicitly
  ([`PROOF.md`](../results/verified029-codex-archlinux-20260616T111534Z/matplotlib__matplotlib-26342/fvk/PROOF.md#L3)).
  We therefore claim **proof-structured reasoning** (a state-transition spec with a
  derived-cache obligation discharged by a symbolic case split over cache-present /
  cache-absent), **not** a machine-checked proof.
- **Attribution.** This is non-curated, so there is **no gold patch on disk** to
  compare against; the gold-comparison row in the Summary is left unavailable rather
  than asserted. The bug-detection value rests on the patch delta (objective) plus the
  audit reasoning in the FVK artifacts (reconstructed). The `V1 -> V2` ordering is
  documented across `FINDINGS.md`, `ITERATION_GUIDANCE.md`, and `fvk_notes.md`; the raw
  ordering could be timestamped from the run transcripts if a reviewer wants it.

## Artifact map

| Claim | Source |
|---|---|
| Issue text / proposed setter | [`prompts/fvk.md#L5`](../results/verified029-codex-archlinux-20260616T111534Z/matplotlib__matplotlib-26342/prompts/fvk.md#L5) |
| Baseline patch | [`solutions/solution_baseline.patch`](../results/verified029-codex-archlinux-20260616T111534Z/matplotlib__matplotlib-26342/solutions/solution_baseline.patch) |
| Baseline scoping reasoning | [`reports/baseline_notes.md#L26`](../results/verified029-codex-archlinux-20260616T111534Z/matplotlib__matplotlib-26342/reports/baseline_notes.md#L26) |
| FVK patch | [`solutions/solution_fvk.patch`](../results/verified029-codex-archlinux-20260616T111534Z/matplotlib__matplotlib-26342/solutions/solution_fvk.patch) |
| Intent item (derived cache) | [`fvk/INTENT_SPEC.md#L17`](../results/verified029-codex-archlinux-20260616T111534Z/matplotlib__matplotlib-26342/fvk/INTENT_SPEC.md#L17) |
| Evidence E6 (code audit) | [`fvk/PUBLIC_EVIDENCE_LEDGER.md#L10`](../results/verified029-codex-archlinux-20260616T111534Z/matplotlib__matplotlib-26342/fvk/PUBLIC_EVIDENCE_LEDGER.md#L10) |
| Obligation PO3 | [`fvk/PROOF_OBLIGATIONS.md#L19`](../results/verified029-codex-archlinux-20260616T111534Z/matplotlib__matplotlib-26342/fvk/PROOF_OBLIGATIONS.md#L19) |
| Adequacy PO6 (discriminates V1) | [`fvk/PROOF_OBLIGATIONS.md#L40`](../results/verified029-codex-archlinux-20260616T111534Z/matplotlib__matplotlib-26342/fvk/PROOF_OBLIGATIONS.md#L40) |
| Finding F2 (V1 defect) | [`fvk/FINDINGS.md#L20`](../results/verified029-codex-archlinux-20260616T111534Z/matplotlib__matplotlib-26342/fvk/FINDINGS.md#L20) |
| Iteration instruction (keep V2) | [`fvk/ITERATION_GUIDANCE.md#L7`](../results/verified029-codex-archlinux-20260616T111534Z/matplotlib__matplotlib-26342/fvk/ITERATION_GUIDANCE.md#L7) |
| Decision trace (V1→V2) | [`reports/fvk_notes.md#L14`](../results/verified029-codex-archlinux-20260616T111534Z/matplotlib__matplotlib-26342/reports/fvk_notes.md#L14) |
| Spec audit (V1 omitted item) | [`fvk/SPEC_AUDIT.md#L8`](../results/verified029-codex-archlinux-20260616T111534Z/matplotlib__matplotlib-26342/fvk/SPEC_AUDIT.md#L8) |
| Compatibility / consumer audit | [`fvk/PUBLIC_COMPATIBILITY_AUDIT.md#L24`](../results/verified029-codex-archlinux-20260616T111534Z/matplotlib__matplotlib-26342/fvk/PUBLIC_COMPATIBILITY_AUDIT.md#L24) |
| Proof status (not run) | [`fvk/PROOF.md#L3`](../results/verified029-codex-archlinux-20260616T111534Z/matplotlib__matplotlib-26342/fvk/PROOF.md#L3) |
| Constructed K core | [`fvk/mini-python-contour-set.k`](../results/verified029-codex-archlinux-20260616T111534Z/matplotlib__matplotlib-26342/fvk/mini-python-contour-set.k), [`fvk/contour-set-set-paths-spec.k`](../results/verified029-codex-archlinux-20260616T111534Z/matplotlib__matplotlib-26342/fvk/contour-set-set-paths-spec.k) |

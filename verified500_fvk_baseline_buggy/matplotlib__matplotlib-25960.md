# matplotlib__matplotlib-25960

## Summary

**Severity:** Medium — baseline reads subfigure spacing from the *public*
`GridSpec.wspace`/`hspace`, so the subplot spacing of any user-built `GridSpec`
leaks into `add_subfigure()` placement and mispositions subfigures for a valid
(if less-common) plotting use case.

Baseline and FVK both passed the official SWE-bench evaluation for issue #25960,
with **different** patches, and the difference is a genuine residual defect, not
cosmetics. Baseline fixed the reported bug (`Figure.subfigures(wspace=, hspace=)`
did nothing) by having the layout arithmetic read `getattr(gs, "wspace", None)` —
but that same arithmetic also runs for the *separate* public `add_subfigure(gs[i])`
path, so an arbitrary user GridSpec's subplot spacing now silently shifts subfigure
positions. The FVK patch routes spacing through a private `_subfigure_wspace`
marker that **only `Figure.subfigures` sets**, so `subfigures(...)` honors spacing
(bug fixed) while `add_subfigure(user_gridspec)` ignores subplot spacing
(historical behavior preserved) — the same separation the human gold patch makes.

| Arm | `add_subfigure(gs[0])` from `add_gridspec(1,2,wspace=0.5)` x-extent | Resolved |
|---|---|---|
| baseline | `[0, 0.4]` — spurious gap injected | no |
| gold (human oracle) | `[0, 0.5]` — no gap | yes |
| **fvk** | `[0, 0.5]` — no gap | **yes** |

## 1. The issue and the real defect

**Matplotlib issue #25960 — "`wspace` and `hspace` in subfigures not working."**
`Figure.subfigures(nrows, ncols, wspace=, hspace=)` ignored the spacing arguments;
the gap between subfigures was always zero
([`problem_statement.md`](../verified500_analysis/matplotlib__matplotlib-25960/_materials/problem_statement.md#L4)).
The fix should make `subfigures(...)` honor the requested spacing.

`SubFigure._redo_transform_rel_fig` computes each subfigure's bbox. Before any
fix, it used only the grid's width/height ratios, so cells always touched
regardless of `wspace`/`hspace`. The user-facing observable is that
**subfigure spacing requests are silently ignored**.

## 2. Baseline's fix — and where it stopped

[Baseline](../verified500_analysis/matplotlib__matplotlib-25960/_materials/baseline.patch)
rewrote `_redo_transform_rel_fig` to compute cell extents with GridSpec-style
spacing arithmetic, reading the spacing from the public GridSpec attributes
(`gs.wspace`/`gs.hspace`, with a `gs._wspace` fallback). This correctly fixes the
reported `subfigures(...)` path.

Baseline's *intent* was exactly right — its notes say it meant for
`add_subfigure(gs[i])` to keep ignoring generic GridSpec spacing:

> *"The issue discussion notes existing cases where `add_subfigure(gs[i])` should
> continue to ignore the default GridSpec `wspace`/`hspace`; therefore the fix
> treats only explicitly stored GridSpec spacing as meaningful for subfigure
> placement."*
> — [`reports/baseline_notes.md`](../results/verified029-codex-archlinux-20260616T111534Z/matplotlib__matplotlib-25960/reports/baseline_notes.md#L27)

But its *implementation* doesn't honor that intent. `_redo_transform_rel_fig` is
shared by both public paths, and reading `getattr(gs, "wspace", None)` picks up
the spacing of *any* GridSpec — including one a user built explicitly with
`add_gridspec(1, 2, wspace=0.5)` and then passed to `add_subfigure(gs[0])`. There
is no signal distinguishing "spacing the user wants between subfigures" from
"spacing the user wants between the subplots of an unrelated GridSpec." Baseline
stopped one obligation short: it never separated the two spacing sources, so the
leak its own notes warned against is exactly what the code does.

## 3. How FVK formally captured the gap

FVK started from an intent spec, not the symptom. The decisive item is precisely
the separation baseline's implementation lost:

> **Intent 5:** *"Generic `GridSpec.wspace` / `GridSpec.hspace` should not become
> subfigure spacing for `add_subfigure(gs[i])`; subfigure spacing is a
> `Figure.subfigures` kwarg."*
> — [`fvk/INTENT_SPEC.md`](../results/verified029-codex-archlinux-20260616T111534Z/matplotlib__matplotlib-25960/fvk/INTENT_SPEC.md#L11)

The evidence ledger pins that intent to a concrete public-discussion fact (not the
reported test), drawn from the issue thread:

> **E5:** *"subfigures ignores the grid spec wspace ... if we want a wspace for a
> set of subfigures that be a kwarg of the subfigure call."* → *"Separate subfigure
> spacing from generic GridSpec spacing."* — status: **"V1 failed; V2 fixed."**
> — [`fvk/PUBLIC_EVIDENCE_LEDGER.md`](../results/verified029-codex-archlinux-20260616T111534Z/matplotlib__matplotlib-25960/fvk/PUBLIC_EVIDENCE_LEDGER.md#L9)

Which is discharged into a formal obligation naming the exact code property:

> **PO5 — Generic `add_subfigure(GridSpec[...])` Does Not Inherit GridSpec Spacing.**
> *"If a GridSpec was not created by `FigureBase.subfigures`, it has no
> `_subfigure_wspace` / `_subfigure_hspace` metadata. Manual layout therefore uses
> `W = H = 0.0`, regardless of generic `gs.wspace` or `gs.hspace`."*
> — [`fvk/PROOF_OBLIGATIONS.md`](../results/verified029-codex-archlinux-20260616T111534Z/matplotlib__matplotlib-25960/fvk/PROOF_OBLIGATIONS.md#L70)

This is the crux of FVK's value: **the leak was located by reasoning about which
GridSpecs carry subfigure intent, not by observing a failure.** The issue asks to
make subfigure spacing work; FVK lifts that into the invariant "only a GridSpec
created by `Figure.subfigures` carries subfigure spacing," and the audit shows
baseline's public-attribute read violates it for every user-built GridSpec.

## 4. From formal output to the fix

The FVK arm's repair is iterative, and the artifacts record the exact step where
the formalism changed the patch.

- **V1** shipped baseline's public-attribute read. The compatibility audit against
  Intent-5/PO5 raised a finding:

  > **F2 — V1 Compatibility Gap: Generic GridSpec Spacing Leaked Into Subfigures.**
  > *"`_redo_transform_rel_fig` read `gs.wspace` / `gs.hspace` directly, so explicit
  > subplot spacing on an arbitrary GridSpec became manual subfigure spacing … V2
  > fixes it by storing `_subfigure_wspace` and `_subfigure_hspace` only on GridSpecs
  > created by `Figure.subfigures`, and by making `_redo_transform_rel_fig` read only
  > those private attributes."*
  > — [`fvk/FINDINGS.md`](../results/verified029-codex-archlinux-20260616T111534Z/matplotlib__matplotlib-25960/fvk/FINDINGS.md#L25)

- The iteration guidance turned the finding into the V2 decision:

  > *"Store `Figure.subfigures` spacing kwargs on the created GridSpec as
  > `_subfigure_wspace` and `_subfigure_hspace`. Use only those private attributes in
  > manual subfigure placement. Preserve GridSpec `wspace` and `hspace` for
  > constrained-layout consumers."*
  > — [`fvk/ITERATION_GUIDANCE.md`](../results/verified029-codex-archlinux-20260616T111534Z/matplotlib__matplotlib-25960/fvk/ITERATION_GUIDANCE.md#L11)

- The decision log records the resulting code change and its provenance:

  > *"`_redo_transform_rel_fig` now reads only `_subfigure_wspace` and
  > `_subfigure_hspace`, and falls back from missing/`None` values to `0.0`. This
  > discharges PO2 and PO5, fixes F2, and preserves the zero-default behavior recorded
  > in F3."*
  > — [`reports/fvk_notes.md`](../results/verified029-codex-archlinux-20260616T111534Z/matplotlib__matplotlib-25960/reports/fvk_notes.md#L16)

The causal chain is fully on the record:

```
INTENT-5  ->  E5 (public discussion: subfigure spacing is a subfigures() kwarg)
          ->  F2 (V1 audit: gs.wspace read leaks user GridSpec spacing)
          ->  PO5 (obligation: only _subfigure_* metadata feeds manual layout)
          ->  ITERATION_GUIDANCE / fvk_notes  ->  V2 patch
```

The resulting [V2 patch](../verified500_analysis/matplotlib__matplotlib-25960/_materials/fvk.patch)
sets the private marker in `subfigures(...)` and reads only that marker in the
layout arithmetic:

```python
# in FigureBase.subfigures, right after building the GridSpec:
gs._subfigure_wspace = wspace
gs._subfigure_hspace = hspace

# in SubFigure._redo_transform_rel_fig:
wspace = getattr(gs, "_subfigure_wspace", None)   # was getattr(gs, "wspace", None)
hspace = getattr(gs, "_subfigure_hspace", None)
```

The downstream geometry arithmetic (average-cell denominators, separators, span
min/max extraction) is byte-identical between baseline and FVK — the *only*
behavioral change is the spacing *source*. The `V1 -> V2` transition was driven by
`F2`/`PO5`, **not** by a new failing test — the hidden test exercises only the
`subfigures(...)` path (see §5).

## 5. Verification

**Tier 2 — executed-by-hand demonstration; not on the harness.** This run produced
no harness RED/GREEN reports (census `proof=no`; the curated analysis has no
`enhanced_tests/_proof` directory), and the prompt bars running tests, Python, or K
tooling. The defect was instead demonstrated by computing the cell geometry by hand
for all three variants against matplotlib 3.6.3-structure source. For
`fig.add_subfigure(fig.add_gridspec(1, 2, wspace=0.5)[0, 0])` (equal width ratios):

| variant | x-extent of the subfigure |
|---|---|
| original / **gold** | `[0, 0.5]` (no gap) |
| **baseline** | `[0, 0.4]` — spurious gap injected |
| **fvk** | `[0, 0.5]` (no gap) |

(baseline: `cell_w = 1/(2 + 0.5) = 0.4`; gold/fvk: `cell_w = 0.5`, because no
`_subfigure_*` metadata exists so `wspace` resolves to `0.0`.) The layout
arithmetic itself is reasoned out obligation-by-obligation in the proof, including
the PO2/PO5 case that a generic GridSpec uses zero manual spacing
([`fvk/PROOF.md`](../results/verified029-codex-archlinux-20260616T111534Z/matplotlib__matplotlib-25960/fvk/PROOF.md#L37)).

**Why the hidden test missed it.** The grading test only exercises
`Figure.subfigures(...)` with explicit `wspace`/`hspace`, which baseline and FVK
both handle; no test calls `add_subfigure()` with a user GridSpec carrying subplot
spacing, so baseline's leak is invisible to the harness.

**FVK matches the human oracle (partial).** The
[gold patch](../verified500_analysis/matplotlib__matplotlib-25960/_materials/gold.patch)
takes a different mechanism — it resets `left/right/bottom/top` on the
`subfigures`-created GridSpec and applies spacing in a separate post-construction
step via `gs.get_grid_positions(...)`, *specifically so* `add_subfigure` won't
inherit GridSpec spacing. FVK's private-marker approach reproduces gold's intent
(separate subfigure spacing from generic subplot spacing) by a different route;
baseline's public-attribute read does not. The behavior on the leak case is
identical between gold and FVK (`[0, 0.5]`), so **GOLD_MATCH: partial** —
equivalent outcome, different implementation.

## 6. Boundaries & honesty

- **Severity: Medium.** This is a genuine residual behavioral defect, not a
  formal-confirmation run: baseline mispositions subfigures for a real, valid usage
  (`add_subfigure` of a user GridSpec that happens to carry subplot spacing). The
  trigger breadth is bounded — it fires only on `add_subfigure(user_gridspec_with_spacing)`,
  a less-common pattern, and the consequence is *misplacement*, not a crash or data
  loss — which is why it is Medium rather than High
  ([`fvk/FINDINGS.md` F2](../results/verified029-codex-archlinux-20260616T111534Z/matplotlib__matplotlib-25960/fvk/FINDINGS.md#L25)).
- **Proof status: constructed, not machine-checked.** The K artifacts
  ([`mini-subfigure-layout.k`](../results/verified029-codex-archlinux-20260616T111534Z/matplotlib__matplotlib-25960/fvk/mini-subfigure-layout.k),
  [`subfigure-layout-spec.k`](../results/verified029-codex-archlinux-20260616T111534Z/matplotlib__matplotlib-25960/fvk/subfigure-layout-spec.k))
  and the `kompile`/`kast`/`kprove` commands were *written but never run* — the FVK
  artifacts say so explicitly
  ([`fvk/PROOF.md`](../results/verified029-codex-archlinux-20260616T111534Z/matplotlib__matplotlib-25960/fvk/PROOF.md#L1)).
  We claim **proof-structured reasoning** (a layout-arithmetic model with obligations
  discharged by construction), **not a machine-checked proof**. The model uses exact
  normalized arithmetic, not Python float rounding, and assumes positive dimensions /
  ratio sums
  ([`fvk/FINDINGS.md` F4](../results/verified029-codex-archlinux-20260616T111534Z/matplotlib__matplotlib-25960/fvk/FINDINGS.md#L69)).
- **Attribution.** The numeric demonstration was computed by hand against
  3.6.3-structure source, not executed on the 3.8-dev tree; confidence is medium and
  is corroborated by the gold patch's design choices, which independently separate
  subfigure spacing from GridSpec subplot spacing. The `V1 -> V2` iteration is
  documented across `FINDINGS.md`, `ITERATION_GUIDANCE.md`, and `fvk_notes.md`.

## Artifact map

| Claim | Source |
|---|---|
| Issue text, repro | [`_materials/problem_statement.md`](../verified500_analysis/matplotlib__matplotlib-25960/_materials/problem_statement.md#L4) |
| Baseline patch | [`_materials/baseline.patch`](../verified500_analysis/matplotlib__matplotlib-25960/_materials/baseline.patch) |
| Baseline intent (meant to ignore GridSpec spacing) | [`reports/baseline_notes.md`](../results/verified029-codex-archlinux-20260616T111534Z/matplotlib__matplotlib-25960/reports/baseline_notes.md#L27) |
| FVK patch | [`_materials/fvk.patch`](../verified500_analysis/matplotlib__matplotlib-25960/_materials/fvk.patch) |
| Gold patch | [`_materials/gold.patch`](../verified500_analysis/matplotlib__matplotlib-25960/_materials/gold.patch) |
| Intent 5 (separation) | [`fvk/INTENT_SPEC.md#L11`](../results/verified029-codex-archlinux-20260616T111534Z/matplotlib__matplotlib-25960/fvk/INTENT_SPEC.md#L11) |
| Evidence E5 (public discussion) | [`fvk/PUBLIC_EVIDENCE_LEDGER.md#L9`](../results/verified029-codex-archlinux-20260616T111534Z/matplotlib__matplotlib-25960/fvk/PUBLIC_EVIDENCE_LEDGER.md#L9) |
| Obligation PO5 | [`fvk/PROOF_OBLIGATIONS.md#L70`](../results/verified029-codex-archlinux-20260616T111534Z/matplotlib__matplotlib-25960/fvk/PROOF_OBLIGATIONS.md#L70) |
| Finding F2 (V1 leak) | [`fvk/FINDINGS.md#L25`](../results/verified029-codex-archlinux-20260616T111534Z/matplotlib__matplotlib-25960/fvk/FINDINGS.md#L25) |
| Iteration decision (private marker) | [`fvk/ITERATION_GUIDANCE.md#L11`](../results/verified029-codex-archlinux-20260616T111534Z/matplotlib__matplotlib-25960/fvk/ITERATION_GUIDANCE.md#L11) |
| Decision trace | [`reports/fvk_notes.md#L16`](../results/verified029-codex-archlinux-20260616T111534Z/matplotlib__matplotlib-25960/reports/fvk_notes.md#L16) |
| Layout proof (PO2/PO5) | [`fvk/PROOF.md#L37`](../results/verified029-codex-archlinux-20260616T111534Z/matplotlib__matplotlib-25960/fvk/PROOF.md#L37) |
| Proof status / residual domain | [`fvk/PROOF.md#L1`](../results/verified029-codex-archlinux-20260616T111534Z/matplotlib__matplotlib-25960/fvk/PROOF.md#L1), [`fvk/FINDINGS.md#L69`](../results/verified029-codex-archlinux-20260616T111534Z/matplotlib__matplotlib-25960/fvk/FINDINGS.md#L69) |
| Constructed K core | [`fvk/mini-subfigure-layout.k`](../results/verified029-codex-archlinux-20260616T111534Z/matplotlib__matplotlib-25960/fvk/mini-subfigure-layout.k), [`fvk/subfigure-layout-spec.k`](../results/verified029-codex-archlinux-20260616T111534Z/matplotlib__matplotlib-25960/fvk/subfigure-layout-spec.k) |

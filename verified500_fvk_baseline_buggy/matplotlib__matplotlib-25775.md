# matplotlib__matplotlib-25775

## Summary

**Severity:** Low — baseline wires per-artist text antialiasing through the Python
graphics-context layer, but on the Cairo backend a *copied* graphics context
(used by path-effect text) carries the `_antialiased` flag without ever applying
it to the underlying cairo context via `ctx.set_antialias(...)`.

Baseline and FVK both passed the official SWE-bench evaluation for issue #25775,
with **different** patches. Baseline added the full `Text.get/set_antialiased`
API, pushed the value into the GC at draw time, and routed AGG and Cairo font
rendering through `gc.get_antialiased()` — a broad, correct fix. The FVK patch
closed one backend-specific seam baseline left open: when a `GraphicsContextCairo`
is *copied* (as path effects do), the copied Python AA flag was never synchronized
into the cairo context, so stroked/path-effect text could render with default
antialiasing regardless of the per-artist setting. The defect is minor (visible
only on Cairo path-effect text); the case matters because FVK found the seam by
**auditing every text-drawing route that consumes a GC against the AA invariant**,
not by running more tests.

| Arm | copied Cairo GC applies AA to cairo context | Resolved |
|---|---|---|
| baseline | no — copy keeps Python flag, not `ctx.set_antialias` | no |
| gold (human oracle) | (no curated gold patch for this run) | — |
| **fvk** | yes — `copy_properties` calls shared `_set_antialias()` | **yes** |

## 1. The issue and the real defect

**Matplotlib issue #25775 — add `get/set_antialiased` to `Text` objects.** Text
antialiasing was tied to the global `rcParams["text.antialiased"]`; the issue asks
for a per-artist property, used "in the drawing stage," replacing direct rcParam
reads with `GraphicsContext` state, and "adjusting Annotations accordingly"
([`prompts/fvk.md`](../results/verified029-codex-archlinux-20260616T111534Z/matplotlib__matplotlib-25775/prompts/fvk.md#L2)).
(The existing report carried no GitHub URL, so none is asserted here.)

Before any fix, `Text.draw` created a graphics context with color/alpha/URL/clip
state but never set antialiasing, and the AGG and Cairo text renderers read the
global rcParam directly when rasterizing glyphs. The user-facing observable is
that **no individual `Text` can override the global antialiasing setting**.

## 2. Baseline's fix — and where it stopped

[Baseline](../results/verified029-codex-archlinux-20260616T111534Z/matplotlib__matplotlib-25775/solutions/solution_baseline.patch)
delivered a wide, coherent fix across `text.py`, `backend_agg.py`,
`mathtext.py`, `_mathtext.py`, and `backend_cairo.py`. Its notes describe the
Cairo work specifically:

> *"Replaced Cairo text font option setup with GC-driven antialiasing, applied it
> to Cairo mathtext glyph drawing too, and made `GraphicsContextCairo.set_antialiased`
> update the base graphics context state so `gc.get_antialiased()` reports the
> current value. Cairo reuses one graphics context object, so `new_gc()` now also
> resets that antialiasing state to the base default."*
> — [`reports/baseline_notes.md`](../results/verified029-codex-archlinux-20260616T111534Z/matplotlib__matplotlib-25775/reports/baseline_notes.md#L42)

Baseline was not careless — it correctly handled `set_antialiased`, `new_gc`, and
the normal Cairo text/mathtext font-option paths. But it overlooked the *copy*
path. Path effects render text by **copying** the graphics context
(`GraphicsContextBase.copy_properties`) and drawing through the copy. That base
copy moves the Python `_antialiased` flag, but Cairo had no `copy_properties`
override to push the copied value into the cairo context via `ctx.set_antialias`.
So the copied context still drew with whatever AA `new_gc()` had reset to.
Baseline covered every GC route except the one that path effects actually use.

## 3. How FVK formally captured the gap

FVK started from an intent spec, not the symptom. The decisive item is the
invariant over *all* font-rendering backends consuming GC state, not just the
direct draw path:

> **I6:** *"Backends that support font antialiasing in this source tree, AGG and
> Cairo, must consume `GraphicsContext` antialiasing state instead of reading
> `rcParams["text.antialiased"]` directly during font rendering."*
> — [`fvk/SPEC.md`](../results/verified029-codex-archlinux-20260616T111534Z/matplotlib__matplotlib-25775/fvk/SPEC.md#L43)

The evidence ledger pins that intent to a concrete code fact found by source audit
— path effects copy GCs before drawing, so a copied Cairo GC must re-synchronize
its AA into the cairo context:

> **E9 (implementation):** *"Path effects copy GCs before drawing paths."* →
> *"Copied Cairo GCs must synchronize copied AA state into the cairo context."*
> — [`fvk/SPEC.md`](../results/verified029-codex-archlinux-20260616T111534Z/matplotlib__matplotlib-25775/fvk/SPEC.md#L63)

Which is discharged into a formal obligation covering the copy explicitly:

> **PO-06: Cairo Text and Cairo GC Copy Consume GC AA.** *"When a Cairo graphics
> context is copied, the cairo context must also receive the copied AA value so
> path-effect text rendering does not fall back to default antialiasing."*
> — [`fvk/PROOF_OBLIGATIONS.md`](../results/verified029-codex-archlinux-20260616T111534Z/matplotlib__matplotlib-25775/fvk/PROOF_OBLIGATIONS.md#L82)

This is the crux of FVK's value: **the residual defect was located by reasoning
over the dispatch graph, not by observation.** The issue says "consume GC AA in the
backends"; FVK enumerates *every* route a Text draw reaches a Cairo GC — direct
draw, mathtext, and the path-effect copy — and the audit (E9) shows the copy route
is the one baseline's per-method edits never reached.

## 4. From formal output to the fix

The FVK arm's repair is iterative, and the artifacts record the exact step where
the formalism changed the patch.

- **V1** shipped baseline's edits. The route audit against I6/PO-06 raised a
  finding:

  > **F1: Cairo path-effect text could ignore copied text AA in V1.** *"`GraphicsContextBase.copy_properties(gc)` copied the Python `_antialiased` flag to
  > false, but Cairo had no `copy_properties` override to apply that copied value to
  > `ctx.set_antialias(...)`. The copied Cairo context could therefore draw the
  > path-effect text with default antialiasing even though the copied GC field said
  > false."*
  > — [`fvk/FINDINGS.md`](../results/verified029-codex-archlinux-20260616T111534Z/matplotlib__matplotlib-25775/fvk/FINDINGS.md#L6)

- The spec audit recorded this as the single V1 mismatch:

  > *"FE-08 | Matches I4/I6 for the path-effect dispatch path discovered in E9. |
  > **Pass after V2 edit**."*
  > — [`fvk/SPEC.md`](../results/verified029-codex-archlinux-20260616T111534Z/matplotlib__matplotlib-25775/fvk/SPEC.md#L118)

- The iteration guidance turned the finding into the V2 edit:

  > *"`GraphicsContextCairo.copy_properties` must synchronize the copied
  > `_antialiased` value into the cairo context. `GraphicsContextCairo.set_antialiased`
  > and `RendererCairo.new_gc` should use the same `_set_antialias` path so Python GC
  > state and cairo context state do not diverge."*
  > — [`fvk/ITERATION_GUIDANCE.md`](../results/verified029-codex-archlinux-20260616T111534Z/matplotlib__matplotlib-25775/fvk/ITERATION_GUIDANCE.md#L7)

- The decision log records the resulting code change and its provenance:

  > *"I fixed it by adding `GraphicsContextCairo.copy_properties`, factoring
  > `_set_antialias`, and using that helper from `set_antialiased`. This keeps copied
  > GCs aligned with the cairo context for text path-effect drawing."*
  > — [`reports/fvk_notes.md`](../results/verified029-codex-archlinux-20260616T111534Z/matplotlib__matplotlib-25775/reports/fvk_notes.md#L9)

The causal chain is fully on the record:

```
SPEC I6  ->  E9 (code audit: path effects copy GCs before drawing)
         ->  F1 (V1 audit: copied Cairo GC keeps Python flag, not ctx AA)
         ->  PO-06 (obligation: copied Cairo GC must apply AA to cairo context)
         ->  ITERATION_GUIDANCE / fvk_notes  ->  V2 patch
```

The resulting [V2 patch](../results/verified029-codex-archlinux-20260616T111534Z/matplotlib__matplotlib-25775/solutions/solution_fvk.patch)
adds the `copy_properties` override and the shared `_set_antialias()` helper so
`set_antialiased`, `new_gc`, and copy all drive the cairo context identically:

```python
def copy_properties(self, gc):
    super().copy_properties(gc)
    self._set_antialias()

def _set_antialias(self):
    self.ctx.set_antialias(
        cairo.ANTIALIAS_DEFAULT if self._antialiased
        else cairo.ANTIALIAS_NONE)
```

The `V1 -> V2` transition was driven by `F1`/`PO-06`, **not** by a new failing
test — the prompt forbids editing tests and no Cairo path-effect AA test exists in
the run (see §5).

## 5. Verification

**Tier 3 — source-and-artifact reviewed; not executed.** This run produced no
harness RED/GREEN reports (census `proof=no`, no curated `_proof` directory) and
no executed demonstration table; the prompt bars running tests, Python, or K
tooling. What was inspected:

- The two patches were diffed: the FVK patch is baseline plus the
  `GraphicsContextCairo.copy_properties` override and the extracted
  `_set_antialias()` helper now driven from `set_antialiased` (remaining diff lines
  are hunk-offset shifts)
  ([`solution_baseline.patch`](../results/verified029-codex-archlinux-20260616T111534Z/matplotlib__matplotlib-25775/solutions/solution_baseline.patch),
  [`solution_fvk.patch`](../results/verified029-codex-archlinux-20260616T111534Z/matplotlib__matplotlib-25775/solutions/solution_fvk.patch)).
- The AA invariant is reasoned out obligation-by-obligation in the proof, including
  the `copyCairoGC` claim that the copied context receives the copied AA value
  ([`fvk/PROOF.md`](../results/verified029-codex-archlinux-20260616T111534Z/matplotlib__matplotlib-25775/fvk/PROOF.md#L90)).

**Gold comparison.** This run is non-curated, so there is no gold patch file to
diff against. The existing report's claim — that FVK closed a backend-specific
copied-GC gap baseline left open — is confirmed against the patches themselves; no
claim about the human oracle's contents is made, since that artifact is absent
here.

## 6. Boundaries & honesty

- **Severity: Low.** The trigger breadth is narrow: baseline already makes
  per-artist AA work for normal AGG/Cairo text, mathtext, and annotations; the
  residual defect is visible only on **Cairo path-effect text** (text drawn through
  a copied graphics context). The value demonstrated is detection completeness, not
  impact magnitude
  ([`fvk/FINDINGS.md` F1](../results/verified029-codex-archlinux-20260616T111534Z/matplotlib__matplotlib-25775/fvk/FINDINGS.md#L6)).
- **Proof status: constructed, not machine-checked.** The K artifacts
  ([`mini-matplotlib-text.k`](../results/verified029-codex-archlinux-20260616T111534Z/matplotlib__matplotlib-25775/fvk/mini-matplotlib-text.k),
  [`matplotlib-text-antialias-spec.k`](../results/verified029-codex-archlinux-20260616T111534Z/matplotlib__matplotlib-25775/fvk/matplotlib-text-antialias-spec.k))
  and the `kompile`/`kast`/`kprove` commands were *written but never run* — the FVK
  artifacts say so explicitly
  ([`fvk/PROOF.md`](../results/verified029-codex-archlinux-20260616T111534Z/matplotlib__matplotlib-25775/fvk/PROOF.md#L1)).
  We claim **proof-structured reasoning** (a dispatch-slice model with obligations
  discharged by construction), **not a machine-checked proof**.
- **Stated out-of-scope boundary.** Per-artist AA for TeX image generation
  (`usetex=True`) is intentionally *not* claimed — the TeX path uses a pre-rendered
  `TexManager` image, not the AGG/Cairo font-AA hooks the issue names; FVK records
  this as F2/PO-09, matching baseline's own decision
  ([`fvk/FINDINGS.md` F2](../results/verified029-codex-archlinux-20260616T111534Z/matplotlib__matplotlib-25775/fvk/FINDINGS.md#L34)).
- **Attribution.** The `V1 -> V2` iteration is documented across `FINDINGS.md`,
  `SPEC.md` (FE-08 "Pass after V2 edit"), `ITERATION_GUIDANCE.md`, and `fvk_notes.md`.
  The existing report's framing (Python-GC-layer propagation vs backend-context-after-copy)
  is consistent with the patches; no claim was reversed.

## Artifact map

| Claim | Source |
|---|---|
| Issue / task statement | [`prompts/fvk.md`](../results/verified029-codex-archlinux-20260616T111534Z/matplotlib__matplotlib-25775/prompts/fvk.md#L2) |
| Baseline patch | [`solutions/solution_baseline.patch`](../results/verified029-codex-archlinux-20260616T111534Z/matplotlib__matplotlib-25775/solutions/solution_baseline.patch) |
| Baseline Cairo design | [`reports/baseline_notes.md`](../results/verified029-codex-archlinux-20260616T111534Z/matplotlib__matplotlib-25775/reports/baseline_notes.md#L42) |
| FVK patch | [`solutions/solution_fvk.patch`](../results/verified029-codex-archlinux-20260616T111534Z/matplotlib__matplotlib-25775/solutions/solution_fvk.patch) |
| Intent I6 (backends consume GC AA) | [`fvk/SPEC.md#L43`](../results/verified029-codex-archlinux-20260616T111534Z/matplotlib__matplotlib-25775/fvk/SPEC.md#L43) |
| Evidence E9 (path effects copy GCs) | [`fvk/SPEC.md#L63`](../results/verified029-codex-archlinux-20260616T111534Z/matplotlib__matplotlib-25775/fvk/SPEC.md#L63) |
| Spec audit (FE-08 pass after V2) | [`fvk/SPEC.md#L118`](../results/verified029-codex-archlinux-20260616T111534Z/matplotlib__matplotlib-25775/fvk/SPEC.md#L118) |
| Obligation PO-06 (copied Cairo GC) | [`fvk/PROOF_OBLIGATIONS.md#L82`](../results/verified029-codex-archlinux-20260616T111534Z/matplotlib__matplotlib-25775/fvk/PROOF_OBLIGATIONS.md#L82) |
| Finding F1 (path-effect AA gap) | [`fvk/FINDINGS.md#L6`](../results/verified029-codex-archlinux-20260616T111534Z/matplotlib__matplotlib-25775/fvk/FINDINGS.md#L6) |
| Out-of-scope F2 (TeX) | [`fvk/FINDINGS.md#L34`](../results/verified029-codex-archlinux-20260616T111534Z/matplotlib__matplotlib-25775/fvk/FINDINGS.md#L34) |
| Iteration edit | [`fvk/ITERATION_GUIDANCE.md#L7`](../results/verified029-codex-archlinux-20260616T111534Z/matplotlib__matplotlib-25775/fvk/ITERATION_GUIDANCE.md#L7) |
| Decision trace | [`reports/fvk_notes.md#L9`](../results/verified029-codex-archlinux-20260616T111534Z/matplotlib__matplotlib-25775/reports/fvk_notes.md#L9) |
| Proof claim (copyCairoGC) | [`fvk/PROOF.md#L90`](../results/verified029-codex-archlinux-20260616T111534Z/matplotlib__matplotlib-25775/fvk/PROOF.md#L90) |
| Proof status (not machine-checked) | [`fvk/PROOF.md#L1`](../results/verified029-codex-archlinux-20260616T111534Z/matplotlib__matplotlib-25775/fvk/PROOF.md#L1) |
| Constructed K core | [`fvk/mini-matplotlib-text.k`](../results/verified029-codex-archlinux-20260616T111534Z/matplotlib__matplotlib-25775/fvk/mini-matplotlib-text.k), [`fvk/matplotlib-text-antialias-spec.k`](../results/verified029-codex-archlinux-20260616T111534Z/matplotlib__matplotlib-25775/fvk/matplotlib-text-antialias-spec.k) |

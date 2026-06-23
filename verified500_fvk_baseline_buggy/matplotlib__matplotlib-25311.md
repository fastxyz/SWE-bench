# matplotlib__matplotlib-25311

## Summary

**Severity:** Low — baseline removes the live backend canvas from *new* draggable
helper pickle state, but `__getstate__` still leaves a legacy/manual `canvas`
dictionary key unsanitized, and the blit predicate dereferences `self.canvas`
without first checking it resolved.

Baseline and FVK both passed the official SWE-bench evaluation for issue #25311,
with **different** patches. Baseline already converted `DraggableBase.canvas` into
a lazy property and stripped `_canvas` in `__getstate__`, fixing the reported
"cannot pickle figure with draggable legend" failure. The FVK patch added two
narrow hardening edits baseline omitted: `__getstate__` now also pops a legacy
`canvas` key (so a pre-rename or hand-built state dict cannot smuggle a live
canvas back onto the pickle path), and `_use_blitting()` now guards
`canvas is not None`. The defect is minor (compatibility-state and GUI-helper
edges); the case matters because FVK found both gaps by **auditing every direct
canvas storage slot on the serialization path against an invariant**, not by
running more tests.

| Arm | legacy `canvas` key sanitized / blit gated on resolved canvas | Resolved |
|---|---|---|
| baseline | no — `__getstate__` misses legacy key; blit assumes canvas | no |
| gold (human oracle) | (no curated gold patch for this run) | — |
| **fvk** | yes — `state.pop("canvas")` + `canvas is not None` guard | **yes** |

## 1. The issue and the real defect

**Matplotlib issue #25311 — unable to pickle a figure with a draggable legend.**
After `leg.set_draggable(True)`, `pickle.dumps(fig)` raised
`TypeError: cannot pickle 'FigureCanvasQTAgg' object`; the same failure occurred
for draggable annotations
([`prompts/fvk.md`](../results/verified028-codex-archlinux-20260616T095431Z/matplotlib__matplotlib-25311/prompts/fvk.md#L2)).
(The existing report carried no GitHub URL, so none is asserted here.)

`DraggableBase.__init__` stored a direct reference to the live backend canvas as
`self.canvas`. Draggable legends and annotations keep a `DraggableBase` subclass
on the artist as `_draggable`, so even though `Figure.__getstate__` already
removes the figure's own `canvas`, pickle traversal still reached the live canvas
through the helper. The user-facing observable is a **figure that cannot be
pickled** whenever dragging is enabled under a GUI backend.

## 2. Baseline's fix — and where it stopped

[Baseline](../results/verified028-codex-archlinux-20260616T095431Z/matplotlib__matplotlib-25311/solutions/solution_baseline.patch)
made a substantial, well-shaped repair: store the canvas as `_canvas`, expose
`canvas` as a lazy property, add `__getstate__`/`__setstate__`, and harden
`disconnect`. Its notes lay out the design clearly:

> *"Changed `DraggableBase` to store the canvas internally as `_canvas`. Added a
> `canvas` property that lazily resolves the current figure canvas … Added
> `__getstate__` to omit the live canvas from draggable helper pickles … Added
> `__setstate__` compatibility handling for older state dictionaries …"*
> — [`reports/baseline_notes.md`](../results/verified028-codex-archlinux-20260616T095431Z/matplotlib__matplotlib-25311/reports/baseline_notes.md#L16)

Baseline was not careless — it correctly localized the bug to the common helper
and preserved draggability across the round trip. But its `__getstate__` only
neutralized `_canvas`; it never popped a legacy `canvas` *key*. Baseline's own
`__setstate__` removed that key on the way in — proving it knew the key could
exist — yet `__getstate__` left it on the way out, so a pre-rename or
manually-built state dict pointing `canvas` at a live backend object would still
be serialized before `__setstate__` could run. And its `_use_blitting` predicate
dereferenced `self.canvas.supports_blit` without checking the property resolved to
`None`. Baseline fixed the reported path and left the compatibility edges around
it.

## 3. How FVK formally captured the gap

FVK started from an intent spec, not the symptom. The decisive item is the
invariant the pickle must satisfy, stated over the whole helper, not the reported
producer:

> **I-003:** *"A draggable helper must not keep a live backend canvas reachable
> from its pickle state."*
> — [`fvk/INTENT_SPEC.md`](../results/verified028-codex-archlinux-20260616T095431Z/matplotlib__matplotlib-25311/fvk/INTENT_SPEC.md#L18)

The evidence ledger pins that intent to a concrete code fact found by source audit
— the helper's `__init__` stores the live canvas and is therefore on the
serialization path that must be sanitized:

> **E-007 (implementation):** *"`DraggableBase.__init__` stores the live canvas and
> connects picklable callbacks."* → *"helper state is on the serialization path and
> must be sanitized."*
> — [`fvk/PUBLIC_EVIDENCE_LEDGER.md`](../results/verified028-codex-archlinux-20260616T095431Z/matplotlib__matplotlib-25311/fvk/PUBLIC_EVIDENCE_LEDGER.md#L13)

Which is discharged into a formal obligation requiring *every* direct canvas slot
to be removed, explicitly including the legacy key:

> **PO-003: Legacy Canvas-Key Robustness.** *"Because V1 introduced a `canvas`
> property and `_canvas` backing field, a helper state with a legacy/manual
> `canvas` dictionary key must still be sanitized by `__getstate__`."*
> — [`fvk/PROOF_OBLIGATIONS.md`](../results/verified028-codex-archlinux-20260616T095431Z/matplotlib__matplotlib-25311/fvk/PROOF_OBLIGATIONS.md#L30)

This is the crux of FVK's value: **the residual defect was located by reasoning
over the state shape, not by observation.** The issue says "pickling fails because
of a live canvas"; FVK lifts that into the invariant "no canvas slot survives
`__getstate__`," and the obligation forces the audit to cover the legacy `canvas`
key that the property rename introduced — exactly the slot V1's `__getstate__`
missed.

## 4. From formal output to the fix

The FVK arm's repair is iterative, and the artifacts record the exact steps where
the formalism changed the patch.

- **V1** shipped baseline's design. The whole-path audit against PO-002/PO-003
  raised a finding:

  > **F-002: V1 missed a legacy/manual `canvas` dictionary key in `__getstate__`.**
  > *"`__setstate__` removed `canvas`, but `__getstate__` did not. If such a key
  > pointed to a live backend canvas, pickle would still try to serialize it before
  > `__setstate__` could run."*
  > — [`fvk/FINDINGS.md`](../results/verified028-codex-archlinux-20260616T095431Z/matplotlib__matplotlib-25311/fvk/FINDINGS.md#L22)

- A second finding caught the unguarded blit predicate:

  > **F-003: Blit predicate should not assume a resolved canvas.** *"`_use_blitting()`
  > dereferenced `self.canvas.supports_blit` … the predicate itself had an
  > unnecessary proof side condition: `self.canvas is not None`."*
  > — [`fvk/FINDINGS.md`](../results/verified028-codex-archlinux-20260616T095431Z/matplotlib__matplotlib-25311/fvk/FINDINGS.md#L39)

- The iteration guidance turned both findings into the two hardening edits:

  > *"1. Add `state.pop("canvas", None)` to `DraggableBase.__getstate__`. —
  > Justification: F-002, PO-002, PO-003. 2. Make `_use_blitting()` return false
  > when `self.canvas` cannot be resolved. — Justification: F-003, PO-007."*
  > — [`fvk/ITERATION_GUIDANCE.md`](../results/verified028-codex-archlinux-20260616T095431Z/matplotlib__matplotlib-25311/fvk/ITERATION_GUIDANCE.md#L11)

- The decision log records the changes and their provenance:

  > *"1. `DraggableBase.__getstate__` now also calls `state.pop("canvas", None)`. …
  > 2. `DraggableBase._use_blitting()` now resolves `canvas = self.canvas` and
  > returns false when the result is `None`."*
  > — [`reports/fvk_notes.md`](../results/verified028-codex-archlinux-20260616T095431Z/matplotlib__matplotlib-25311/reports/fvk_notes.md#L15)

The causal chain is fully on the record:

```
INTENT I-003  ->  E-007 (code audit: helper __init__ stores live canvas; key renamed)
              ->  F-002 (V1 audit: __getstate__ misses legacy `canvas` key)
              ->  PO-003 (obligation: every canvas slot, incl. legacy key, sanitized)
              ->  F-003/PO-007 (blit must be gated on a resolved canvas)
              ->  ITERATION_GUIDANCE / fvk_notes  ->  V2 patch
```

The resulting [V2 patch](../results/verified028-codex-archlinux-20260616T095431Z/matplotlib__matplotlib-25311/solutions/solution_fvk.patch)
adds exactly two lines of behavior on top of baseline:

```python
def __getstate__(self):
    state = self.__dict__.copy()
    state.pop("canvas", None)          # <- added by FVK
    state["_canvas"] = None
    ...

def _use_blitting(self):
    canvas = self.canvas
    return self._use_blit and canvas is not None and canvas.supports_blit  # <- guard added
```

The `V1 -> V2` transition was driven by `F-002`/`F-003` and `PO-003`/`PO-007`,
**not** by a new failing test — the prompt forbids editing tests and no
legacy-key or detached-canvas test exists in the run (see §5).

## 5. Verification

**Tier 3 — source-and-artifact reviewed; not executed.** This run produced no
harness RED/GREEN reports (census `proof=no`, no curated `_proof` directory) and
no executed demonstration table; the prompt bars running tests, Python, or K
tooling. What was inspected:

- The two patches were diffed: the FVK patch is baseline plus exactly the
  `state.pop("canvas", None)` line and the `canvas is not None` guard in
  `_use_blitting()` (remaining diff lines are pure hunk-offset shifts)
  ([`solution_baseline.patch`](../results/verified028-codex-archlinux-20260616T095431Z/matplotlib__matplotlib-25311/solutions/solution_baseline.patch),
  [`solution_fvk.patch`](../results/verified028-codex-archlinux-20260616T095431Z/matplotlib__matplotlib-25311/solutions/solution_fvk.patch)).
- The serialization invariant is reasoned out claim-by-claim in the proof
  (getstate strips every canvas slot; setstate defaults `_canvas`; blit returns
  false with no canvas)
  ([`fvk/PROOF.md`](../results/verified028-codex-archlinux-20260616T095431Z/matplotlib__matplotlib-25311/fvk/PROOF.md#L29)).

**Gold comparison.** This run is non-curated, so there is no gold patch file to
diff against. The existing report's claim — that FVK hardened the draggable state
boundary beyond baseline — is confirmed against the patches themselves; no claim
about the human oracle's contents is made, since that artifact is absent here.

## 6. Boundaries & honesty

- **Severity: Low.** The trigger breadth is narrow: baseline already fixes the
  reported pickling failure for the normal helper state; the residual defect only
  fires on a *legacy or manually-built* state dict that still carries a `canvas`
  key, or on a detached helper whose canvas cannot resolve during blitting — both
  compatibility/GUI-lifecycle edges. The value demonstrated is detection
  completeness, not impact magnitude
  ([`fvk/FINDINGS.md` F-002](../results/verified028-codex-archlinux-20260616T095431Z/matplotlib__matplotlib-25311/fvk/FINDINGS.md#L22)).
- **Proof status: constructed, not machine-checked.** The K artifacts
  ([`mini-python-pickle.k`](../results/verified028-codex-archlinux-20260616T095431Z/matplotlib__matplotlib-25311/fvk/mini-python-pickle.k),
  [`draggable-pickle-spec.k`](../results/verified028-codex-archlinux-20260616T095431Z/matplotlib__matplotlib-25311/fvk/draggable-pickle-spec.k))
  and the `kompile`/`kast`/`kprove` commands were *written but never run* — the FVK
  artifacts say so explicitly
  ([`fvk/PROOF.md`](../results/verified028-codex-archlinux-20260616T095431Z/matplotlib__matplotlib-25311/fvk/PROOF.md#L1)).
  We claim **proof-structured reasoning** (a state-transition model with
  obligations discharged by construction), **not a machine-checked proof**. The
  model abstracts full Python pickle traversal and backend internals
  ([`fvk/FINDINGS.md` F-005](../results/verified028-codex-archlinux-20260616T095431Z/matplotlib__matplotlib-25311/fvk/FINDINGS.md#L71)).
- **Attribution.** The `V1 -> V2` iteration is documented across `FINDINGS.md`,
  `ITERATION_GUIDANCE.md`, and `fvk_notes.md`. One nuance worth flagging: baseline's
  notes describe blit-gating "on the currently resolved canvas," but the V1 code it
  shipped still dereferenced `self.canvas` without a `None` guard — F-003 is what
  closed that gap; the existing report's framing is consistent with this.

## Artifact map

| Claim | Source |
|---|---|
| Issue / task statement | [`prompts/fvk.md`](../results/verified028-codex-archlinux-20260616T095431Z/matplotlib__matplotlib-25311/prompts/fvk.md#L2) |
| Baseline patch | [`solutions/solution_baseline.patch`](../results/verified028-codex-archlinux-20260616T095431Z/matplotlib__matplotlib-25311/solutions/solution_baseline.patch) |
| Baseline design (property, getstate/setstate) | [`reports/baseline_notes.md`](../results/verified028-codex-archlinux-20260616T095431Z/matplotlib__matplotlib-25311/reports/baseline_notes.md#L16) |
| FVK patch | [`solutions/solution_fvk.patch`](../results/verified028-codex-archlinux-20260616T095431Z/matplotlib__matplotlib-25311/solutions/solution_fvk.patch) |
| Intent I-003 (no live canvas in pickle) | [`fvk/INTENT_SPEC.md#L18`](../results/verified028-codex-archlinux-20260616T095431Z/matplotlib__matplotlib-25311/fvk/INTENT_SPEC.md#L18) |
| Evidence E-007 (helper stores live canvas) | [`fvk/PUBLIC_EVIDENCE_LEDGER.md#L13`](../results/verified028-codex-archlinux-20260616T095431Z/matplotlib__matplotlib-25311/fvk/PUBLIC_EVIDENCE_LEDGER.md#L13) |
| Obligation PO-003 (legacy canvas key) | [`fvk/PROOF_OBLIGATIONS.md#L30`](../results/verified028-codex-archlinux-20260616T095431Z/matplotlib__matplotlib-25311/fvk/PROOF_OBLIGATIONS.md#L30) |
| Finding F-002 (`__getstate__` legacy key) | [`fvk/FINDINGS.md#L22`](../results/verified028-codex-archlinux-20260616T095431Z/matplotlib__matplotlib-25311/fvk/FINDINGS.md#L22) |
| Finding F-003 (blit guard) | [`fvk/FINDINGS.md#L39`](../results/verified028-codex-archlinux-20260616T095431Z/matplotlib__matplotlib-25311/fvk/FINDINGS.md#L39) |
| Iteration edits | [`fvk/ITERATION_GUIDANCE.md#L11`](../results/verified028-codex-archlinux-20260616T095431Z/matplotlib__matplotlib-25311/fvk/ITERATION_GUIDANCE.md#L11) |
| Decision trace | [`reports/fvk_notes.md#L15`](../results/verified028-codex-archlinux-20260616T095431Z/matplotlib__matplotlib-25311/reports/fvk_notes.md#L15) |
| Proof claims | [`fvk/PROOF.md#L29`](../results/verified028-codex-archlinux-20260616T095431Z/matplotlib__matplotlib-25311/fvk/PROOF.md#L29) |
| Proof status / residual boundary | [`fvk/PROOF.md#L1`](../results/verified028-codex-archlinux-20260616T095431Z/matplotlib__matplotlib-25311/fvk/PROOF.md#L1), [`fvk/FINDINGS.md#L71`](../results/verified028-codex-archlinux-20260616T095431Z/matplotlib__matplotlib-25311/fvk/FINDINGS.md#L71) |
| Constructed K core | [`fvk/mini-python-pickle.k`](../results/verified028-codex-archlinux-20260616T095431Z/matplotlib__matplotlib-25311/fvk/mini-python-pickle.k), [`fvk/draggable-pickle-spec.k`](../results/verified028-codex-archlinux-20260616T095431Z/matplotlib__matplotlib-25311/fvk/draggable-pickle-spec.k) |

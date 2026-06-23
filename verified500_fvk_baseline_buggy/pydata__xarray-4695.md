# pydata__xarray-4695

## Summary

**Severity:** Medium — baseline misroutes a dynamically constructed dimension
indexer into a reserved `.sel()` keyword, but only when a dimension/group name
collides with `method` / `tolerance` / `drop` *and* flows through a non-`.loc`
selection helper, so the trigger is real but narrow.

Baseline and FVK both passed the official SWE-bench evaluation for issue #4695
with **different** patches. Baseline fixed the reported `.loc` dispatch path;
FVK kept that fix and additionally repaired **the same keyword-collision pattern
in two internal helpers** (`_iter_over_selections` in `computation.py` and
`GroupBy._yield_binary_applied` in `groupby.py`) that still called
`.sel(**{dim: value})`. FVK located the surviving call sites by lifting the
issue into an invariant — *dynamically derived dimension names are data, not
call-site option names* — and auditing every dispatch path that must satisfy
it, not by running more tests.

| Arm | `test_loc_dim_name_collision_with_sel_params` (`.loc` path) | Helper-path collision resolved |
|---|---|---|
| baseline | [resolved](../results/verified031-codex-archlinux-20260616T140808Z/pydata__xarray-4695/solutions/solution_baseline.patch) | no |
| gold (human oracle) | resolved (`.loc` only) | no |
| **fvk** | [resolved](../results/verified031-codex-archlinux-20260616T140808Z/pydata__xarray-4695/solutions/solution_fvk.patch) | **yes** |

## 1. The issue and the real defect

**GitHub issue pydata/xarray#4695** — *"Naming a dimension `method` throws error
when calling `.loc`":* a dimension may legitimately be named `method`, but
`.sel()` also reserves `method=` for inexact matching, so dispatching the `.loc`
mapping by keyword collides
([`prompts/fvk.md`](../results/verified031-codex-archlinux-20260616T140808Z/pydata__xarray-4695/prompts/fvk.md#L8)).

The canonical failing shape:

```python
DataArray(..., dims=["dim1", "method"]).loc[dict(dim1="x", method="a")]
```

`DataArray._LocIndexer.__getitem__` built a dimension-to-label mapping and then
unpacked it as `self.data_array.sel(**key)`. With a dimension named `method`,
keyword unpacking binds the label `"a"` to the reserved inexact-match `method`
option, and pandas rejects it with `ValueError: Invalid fill method`
([`PUBLIC_EVIDENCE_LEDGER.md` E4](../results/verified031-codex-archlinux-20260616T140808Z/pydata__xarray-4695/fvk/PUBLIC_EVIDENCE_LEDGER.md#L28)).
The user-facing observable: a valid label selection raises instead of selecting.

## 2. Baseline's fix — and where it stopped

[Baseline](../results/verified031-codex-archlinux-20260616T140808Z/pydata__xarray-4695/solutions/solution_baseline.patch)
changed the one direct `.loc` call from `sel(**key)` to positional `sel(key)`:

```python
-        return self.data_array.sel(**key)
+        return self.data_array.sel(key)
```

That resolves the reported regression and is logically identical to the gold
fix. Baseline was not careless — its notes show it *consciously considered* the
neighboring `.sel(**{dim: value})` call sites and chose to leave them alone:

> *"I considered changing other internal `.sel(**{dim: value})` call sites, but
> the reported failure is specifically in `DataArray.loc`, and `Dataset.loc`
> already demonstrates the targeted fix pattern. I kept the code change minimal
> to avoid expanding the behavioral surface beyond the issue."*
> — [`reports/baseline_notes.md`](../results/verified031-codex-archlinux-20260616T140808Z/pydata__xarray-4695/reports/baseline_notes.md#L39)

That reasoning minimizes blast radius but leaves the **same invariant unmet on
other paths**: any helper that dynamically constructs a one-item `{dim: value}`
indexer and then unpacks it has the identical collision. Baseline fixed exactly
one of the three dispatch sites that feed `.sel`.

## 3. How FVK formally captured the gap

FVK started from a spec, not the symptom. The decisive intent item generalizes
the issue beyond the single reported method:

> **I5.** *Internal helpers that dynamically construct a dimension indexer and
> pass it to `.sel` must preserve the dimension name as data. Dynamically
> derived dimension names must not be unpacked into `.sel` keyword parameters.*
> — [`INTENT_SPEC.md`](../results/verified031-codex-archlinux-20260616T140808Z/pydata__xarray-4695/fvk/INTENT_SPEC.md#L25)

The evidence ledger pins that intent to a code fact found by source audit — the
generalization to *any* colliding name, drawn from the issue's own wording, not
from the reported test:

> **E3 — Name Irrelevance.** *Quoted evidence: `The name of the dimension should
> be irrelevant.` Semantic obligation: dynamically constructed dimension names
> must remain indexer keys even when they collide with `.sel` parameter names.*
> — [`PUBLIC_EVIDENCE_LEDGER.md`](../results/verified031-codex-archlinux-20260616T140808Z/pydata__xarray-4695/fvk/PUBLIC_EVIDENCE_LEDGER.md#L20)

cross-checked against the `.sel` signature audit (E7) that shows the positional
`indexers` mapping is a *separate channel* from the reserved options
([`PUBLIC_EVIDENCE_LEDGER.md` E7](../results/verified031-codex-archlinux-20260616T140808Z/pydata__xarray-4695/fvk/PUBLIC_EVIDENCE_LEDGER.md#L56)).
Both discharge into a formal obligation that is *not* about `.loc` at all:

> **PO-4 — Dynamic Single-Indexer Helper Dispatch.** *Any audited internal
> helper that constructs `{dim: value}` specifically to select along a dynamic
> dimension must pass that mapping positionally to `.sel`. It must not use
> keyword expansion.*
> — [`PROOF_OBLIGATIONS.md`](../results/verified031-codex-archlinux-20260616T140808Z/pydata__xarray-4695/fvk/PROOF_OBLIGATIONS.md#L28)

This is the crux of FVK's value: **the surviving call sites were located by
reasoning, not observation.** The issue says "a dimension named `method` must
work"; FVK lifts that into an invariant over *every* contributor that dispatches
a dynamic indexer into `.sel`, then the source audit names the two contributors
— `computation.py::_iter_over_selections` and `groupby.py::_yield_binary_applied`
— that bypass the positional form and would re-trigger the exact bug.

## 4. From formal output to the fix

The FVK arm's repair is iterative. V1 fixed only `.loc`; the completeness audit
against the spec raised the finding that drove V2:

> **FVK-F2 — Same Dynamic-Indexer Pattern Outside `.loc`.** *Classification:
> code bug, fixed in V2. Pre-V2 observed behavior by source inspection: the
> helper calls used `.sel(**{dim: value})`, so `dim == "method"` would bind the
> reserved `.sel(method=...)` option instead of an indexer. Proof obligations:
> PO-1, PO-4, PO-5, PO-6.*
> — [`FINDINGS.md`](../results/verified031-codex-archlinux-20260616T140808Z/pydata__xarray-4695/fvk/FINDINGS.md#L19)

The iteration guidance turned the finding into an instruction for V2:

> *"Apply the same mapping-form dispatch to `repo/xarray/core/computation.py`:
> `obj.sel({dim: value})`. … Apply the same mapping-form dispatch to
> `repo/xarray/core/groupby.py`: `other.sel({self._group.name: group_value})`.
> This is justified by `FVK-F2` and `PO-4`."*
> — [`ITERATION_GUIDANCE.md`](../results/verified031-codex-archlinux-20260616T140808Z/pydata__xarray-4695/fvk/ITERATION_GUIDANCE.md#L12)

The decision log records the resulting code changes and their provenance:

> *"Decision: change `_iter_over_selections` from `obj.sel(**{dim: value})` to
> `obj.sel({dim: value})`. … `FVK-F2` identifies the same dynamic
> dimension-name collision outside `.loc`. `PO-4` requires audited helpers that
> construct `{dim: value}` … to pass that mapping positionally."*
> — [`reports/fvk_notes.md`](../results/verified031-codex-archlinux-20260616T140808Z/pydata__xarray-4695/reports/fvk_notes.md#L29)

The causal chain is fully on the record:

```
INTENT I5  ->  E3 (issue: dimension name is irrelevant)
           ->  E7 (audit: .sel separates positional indexers from options)
           ->  PO-4 (obligation: dynamic helpers dispatch {dim: value} positionally)
           ->  FVK-F2 (audit: computation.py + groupby.py still keyword-unpack)
           ->  ITERATION_GUIDANCE / fvk_notes  ->  V2 patch
```

The resulting
[V2 patch](../results/verified031-codex-archlinux-20260616T140808Z/pydata__xarray-4695/solutions/solution_fvk.patch)
applies the identical positional-mapping repair to both helpers:

```python
-            obj_sel = obj.sel(**{dim: value})            # computation.py
+            obj_sel = obj.sel({dim: value})
-                other_sel = other.sel(**{self._group.name: group_value})   # groupby.py
+                other_sel = other.sel({self._group.name: group_value})
```

The `V1 -> V2` transition was driven by `FVK-F2` / `PO-4`, **not** by a new
failing test — the official `FAIL_TO_PASS` exercises only the `.loc` path, and
no execution environment existed in this run (see §5).

## 5. Verification

**Tier 3 — source-and-artifact reviewed; not executed.** This run had no
execution environment, and the task explicitly forbade running tests, Python,
or K tooling
([`prompts/fvk.md`](../results/verified031-codex-archlinux-20260616T140808Z/pydata__xarray-4695/prompts/fvk.md#L26)).
No harness RED/GREEN reports exist for this instance (non-curated; no
`verified500_analysis` materials). The confirmation rests on source inspection
of the two patches plus the FVK artifact chain:

- The baseline tree provably still contains the unsafe pattern at two sites —
  `obj.sel(**{dim: value})` in `_iter_over_selections` and
  `other.sel(**{self._group.name: group_value})` in `_yield_binary_applied` —
  both visible as the removed `-` lines in
  [`solution_fvk.patch`](../results/verified031-codex-archlinux-20260616T140808Z/pydata__xarray-4695/solutions/solution_fvk.patch#L9).
- The FVK patch replaces both with the positional mapping form already proven
  safe for the `.loc` path, so a dimension/group named `method` survives as an
  indexer key.

The behavioral argument is reasoned, not run. For the dynamic name `method`:

| Variant | Helper dispatch | Meaning |
|---|---|---|
| baseline | `obj.sel(method="a")` | reserved inexact-match option (ambiguous / error) |
| **fvk** | `obj.sel({"method": "a"})` | `"method"` preserved as a dimension indexer |

This corresponds to the constructed claims `HELPER-METHOD-CONCRETE` and
`HELPER-GENERIC`
([`FORMAL_SPEC_ENGLISH.md`](../results/verified031-codex-archlinux-20260616T140808Z/pydata__xarray-4695/fvk/FORMAL_SPEC_ENGLISH.md#L17)),
which assert helper dispatch reaches downstream `.sel` with `{D: V}` as an
indexer mapping and exact-match method state — but they are *constructed*, not
machine-checked (see §6).

**Gold comparison.** The official gold patch covered only the direct `.loc`
change (`return self.data_array.sel(key)`), matching baseline. Gold does **not**
include the computation/groupby helper repair, so FVK is not a byte-for-byte
gold match here; there is no gold file to link in this non-curated case. The
stronger confirmation is the source-level invariant: FVK found the same root
keyword-collision pattern in additional dynamic dispatch sites and applied the
same mapping-form repair the maintainers shipped for `.loc`.

## 6. Boundaries & honesty

- **Severity: Medium.** The trigger is real but conjunctive: a dimension or
  group name must collide with a reserved `.sel()` parameter (`method`,
  `tolerance`, `drop`) *and* the selection must flow through one of the two
  internal helpers rather than the already-fixed `.loc` path. That is a genuine
  correctness defect (silent option-binding / spurious error), not cosmetics,
  but the colliding-name precondition keeps the practical blast radius moderate
  — hence Medium, not High.
- **Proof status: constructed, not machine-checked.** The K artifacts
  ([`mini-python-loc.k`](../results/verified031-codex-archlinux-20260616T140808Z/pydata__xarray-4695/fvk/mini-python-loc.k),
  [`dataarray-loc-spec.k`](../results/verified031-codex-archlinux-20260616T140808Z/pydata__xarray-4695/fvk/dataarray-loc-spec.k))
  and the `kprove` commands were *written but never run* — the FVK artifacts say
  so explicitly
  ([`fvk/PROOF.md`](../results/verified031-codex-archlinux-20260616T140808Z/pydata__xarray-4695/fvk/PROOF.md#L3),
  [obligation PO-8](../results/verified031-codex-archlinux-20260616T140808Z/pydata__xarray-4695/fvk/PROOF_OBLIGATIONS.md#L62),
  [finding FVK-F4](../results/verified031-codex-archlinux-20260616T140808Z/pydata__xarray-4695/fvk/FINDINGS.md#L47)).
  We therefore claim **proof-structured reasoning** (a formal spec with
  obligations discharged by construction), **not a machine-checked proof**. The
  earlier "Concrete demonstration" prose in this doc was not an executed
  observation; it is reproduced above as the *reasoned* behavioral argument it
  actually is.
- **Attribution.** The `.loc` fix is shared by baseline, gold, and FVK; FVK's
  distinct contribution is the two helper repairs in `computation.py` and
  `groupby.py`, confirmed by the FVK dispatch obligation (PO-4) and source
  inspection rather than by gold equality or a harness verdict. The full
  `V1 -> V2` ordering can be timestamped from
  [`transcripts/fvk.jsonl.gz`](../results/verified031-codex-archlinux-20260616T140808Z/pydata__xarray-4695/transcripts/fvk.jsonl.gz)
  if a reviewer wants the raw trace.

## Artifact map

| Claim | Source |
|---|---|
| Issue text, repro | [`prompts/fvk.md`](../results/verified031-codex-archlinux-20260616T140808Z/pydata__xarray-4695/prompts/fvk.md#L8) |
| Symptom localization (E4) | [`PUBLIC_EVIDENCE_LEDGER.md#L28`](../results/verified031-codex-archlinux-20260616T140808Z/pydata__xarray-4695/fvk/PUBLIC_EVIDENCE_LEDGER.md#L28) |
| Baseline patch | [`solutions/solution_baseline.patch`](../results/verified031-codex-archlinux-20260616T140808Z/pydata__xarray-4695/solutions/solution_baseline.patch) |
| Baseline reasoning (left helpers alone) | [`reports/baseline_notes.md#L39`](../results/verified031-codex-archlinux-20260616T140808Z/pydata__xarray-4695/reports/baseline_notes.md#L39) |
| FVK patch | [`solutions/solution_fvk.patch`](../results/verified031-codex-archlinux-20260616T140808Z/pydata__xarray-4695/solutions/solution_fvk.patch) |
| Intent I5 | [`INTENT_SPEC.md#L25`](../results/verified031-codex-archlinux-20260616T140808Z/pydata__xarray-4695/fvk/INTENT_SPEC.md#L25) |
| Evidence E3 (name irrelevance) | [`PUBLIC_EVIDENCE_LEDGER.md#L20`](../results/verified031-codex-archlinux-20260616T140808Z/pydata__xarray-4695/fvk/PUBLIC_EVIDENCE_LEDGER.md#L20) |
| Evidence E7 (`.sel` API separation) | [`PUBLIC_EVIDENCE_LEDGER.md#L56`](../results/verified031-codex-archlinux-20260616T140808Z/pydata__xarray-4695/fvk/PUBLIC_EVIDENCE_LEDGER.md#L56) |
| Obligation PO-4 | [`PROOF_OBLIGATIONS.md#L28`](../results/verified031-codex-archlinux-20260616T140808Z/pydata__xarray-4695/fvk/PROOF_OBLIGATIONS.md#L28) |
| Finding FVK-F2 | [`FINDINGS.md#L19`](../results/verified031-codex-archlinux-20260616T140808Z/pydata__xarray-4695/fvk/FINDINGS.md#L19) |
| Honesty finding FVK-F4 | [`FINDINGS.md#L47`](../results/verified031-codex-archlinux-20260616T140808Z/pydata__xarray-4695/fvk/FINDINGS.md#L47) |
| Iteration instruction (V1→V2) | [`ITERATION_GUIDANCE.md#L12`](../results/verified031-codex-archlinux-20260616T140808Z/pydata__xarray-4695/fvk/ITERATION_GUIDANCE.md#L12) |
| Decision trace (computation.py) | [`reports/fvk_notes.md#L29`](../results/verified031-codex-archlinux-20260616T140808Z/pydata__xarray-4695/reports/fvk_notes.md#L29) |
| Helper claims (FORMAL) | [`FORMAL_SPEC_ENGLISH.md#L17`](../results/verified031-codex-archlinux-20260616T140808Z/pydata__xarray-4695/fvk/FORMAL_SPEC_ENGLISH.md#L17) |
| Constructed K core | [`mini-python-loc.k`](../results/verified031-codex-archlinux-20260616T140808Z/pydata__xarray-4695/fvk/mini-python-loc.k), [`dataarray-loc-spec.k`](../results/verified031-codex-archlinux-20260616T140808Z/pydata__xarray-4695/fvk/dataarray-loc-spec.k) |
| Proof status (not machine-checked) | [`fvk/PROOF.md#L3`](../results/verified031-codex-archlinux-20260616T140808Z/pydata__xarray-4695/fvk/PROOF.md#L3), [`PROOF_OBLIGATIONS.md#L62`](../results/verified031-codex-archlinux-20260616T140808Z/pydata__xarray-4695/fvk/PROOF_OBLIGATIONS.md#L62) |
| No-execution constraint | [`prompts/fvk.md#L26`](../results/verified031-codex-archlinux-20260616T140808Z/pydata__xarray-4695/prompts/fvk.md#L26) |
| Raw model traces | [`transcripts/fvk.jsonl.gz`](../results/verified031-codex-archlinux-20260616T140808Z/pydata__xarray-4695/transcripts/fvk.jsonl.gz) |

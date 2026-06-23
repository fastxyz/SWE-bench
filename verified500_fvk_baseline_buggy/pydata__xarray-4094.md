# pydata__xarray-4094

## Summary

**Severity:** High — baseline silently loses legitimate length-1 dimensions during a
stack/unstack round trip, a data-shape/data-loss defect that survives even in the
official human fix.

Baseline and FVK both passed the official SWE-bench evaluation for the
`to_unstacked_dataset` round-trip issue, but baseline (and the human gold fix) reconstruct
each variable with an unqualified `.squeeze(drop=True)` that strips *every* size-1
dimension — destroying real length-1 sample dimensions. FVK replaced the blanket squeeze
with a per-dimension squeeze scoped only to the consumed stacked level, and located the
defect by **formalizing sample dimensions as frame conditions and auditing the squeeze
against that invariant**, not by running more tests.

| Arm | [`test_to_unstacked_dataset_preserves_length1_dim`](../verified500_analysis/pydata__xarray-4094/enhanced_tests/test_fvk_regression.py) | Resolved |
|---|---|---|
| baseline | [**FAIL (RED)**](../verified500_analysis/pydata__xarray-4094/enhanced_tests/_proof/baseline.report.json) | no |
| gold (human oracle) | [**FAIL (RED)**](../verified500_analysis/pydata__xarray-4094/enhanced_tests/_proof/gold.report.json) | no |
| **fvk** | [**PASS (GREEN)**](../verified500_analysis/pydata__xarray-4094/enhanced_tests/_proof/fvk.report.json) | **yes** |

## 1. The issue and the real defect

The reported bug — *"to_unstacked_dataset broken for single-dim variables"* — is that
round-tripping a dataset through `to_stacked_array(...).to_unstacked_dataset(...)` raises
`MergeError: conflicting values for variable 'y'`
([`problem_statement.md`](../verified500_analysis/pydata__xarray-4094/_materials/problem_statement.md#L1)).

`DataArray.to_unstacked_dataset()` is the inverse of `Dataset.to_stacked_array()`: it
selects each variable's level out of the stacked array and must reconstruct each original
variable with the same dimensions, coordinates, and values. The original reconstruction
loop was:

```python
data_dict[k] = self.sel({variable_dim: k}).squeeze(drop=True)
```

`squeeze()` with no `dim=` argument removes **every** size-1 dimension on the selection.
That is too broad: it also removes a *legitimate* length-1 sample dimension, not just the
consumed stacked index — silently turning a `('x',)`-shaped variable into a scalar.

## 2. Baseline's fix — and where it stopped

[Baseline](../results/verified031-codex-archlinux-20260616T140808Z/pydata__xarray-4094/solutions/solution_baseline.patch)
correctly diagnosed the `MergeError`: the selected arrays keep scalar coordinate metadata
for the consumed stacked dimension and level, which `Dataset(data_dict)` then tries to
merge as conflicting values. Baseline's notes show a deliberate, narrow repair — it
dropped the consumed stacked coordinate metadata after selecting and squeezing each
variable:

> *"after selecting and squeezing each variable in `to_unstacked_dataset()`, the code now
> drops the stacked coordinate name and the consumed MultiIndex level coordinate when
> present."*
> — [`reports/baseline_notes.md`](../results/verified031-codex-archlinux-20260616T140808Z/pydata__xarray-4094/reports/baseline_notes.md#L17)

That fixes the reported `MergeError`. But baseline kept the unqualified
`.squeeze(drop=True)` and never questioned it — the reported test's sample dimension has
length ≥ 2, so the over-broad squeeze is invisible. The obligation it left unmet:
**a legitimate length-1 sample dimension must survive unstacking.**

## 3. How FVK formally captured the gap

FVK started from an intent spec, not the symptom. The decisive intent item generalizes
the round-trip contract to length-1 dimensions:

> *"Legitimate sample dimensions must be preserved even when their length is one; only the
> consumed stacked coordinate and placeholder dimensions introduced for missing stacked
> levels may be squeezed away."*
> — [`fvk/INTENT_SPEC.md`](../results/verified031-codex-archlinux-20260616T140808Z/pydata__xarray-4094/fvk/INTENT_SPEC.md#L19)

The evidence ledger pins that intent to two concrete code facts found by source audit —
**not** to the reported test. The first establishes sample dimensions as frame conditions;
the second flags the implementation that violates it:

> **E5:** *`repo/xarray/core/dataset.py` docstring — "`sample_dims`: Dimensions that will
> not be stacked" → Sample dimensions are frame conditions and should survive unstacking.
> Encoded in PO4; V1 violated this for length-one sample dimensions.*
> — [`fvk/PUBLIC_EVIDENCE_LEDGER.md`](../results/verified031-codex-archlinux-20260616T140808Z/pydata__xarray-4094/fvk/PUBLIC_EVIDENCE_LEDGER.md#L11)

> **E8:** *V1 implementation — `.squeeze(drop=True)` without a `dim` argument →
> Implementation-derived behavior: all length-one dimensions are removed. Finding F2;
> rejected as inconsistent with E4-E5.*
> — [`fvk/PUBLIC_EVIDENCE_LEDGER.md`](../results/verified031-codex-archlinux-20260616T140808Z/pydata__xarray-4094/fvk/PUBLIC_EVIDENCE_LEDGER.md#L14)

These discharge into a formal obligation:

> **PO4: Sample dimensions are preserved.** *No legitimate sample dimension is squeezed
> solely because its length is one. Only names in `dims_to_squeeze` are passed to
> `squeeze`; the consumed stacked dimension is added only when it remains singleton after
> selection and does not represent a remaining real MultiIndex level.*
> — [`fvk/PROOF_OBLIGATIONS.md`](../results/verified031-codex-archlinux-20260616T140808Z/pydata__xarray-4094/fvk/PROOF_OBLIGATIONS.md#L26)

This is the crux: the second defect was located by **reasoning**. The `sample_dims`
docstring (E5) says sample dimensions are not stacked, so unstacking must preserve them;
the code audit (E8) shows the unqualified squeeze removes *all* size-1 dimensions —
contradicting the invariant for the length-1 case.

## 4. From formal output to the fix

The FVK arm's repair is iterative, and the artifacts record the exact step where the
formalism changed the patch.

- **V1** kept baseline's coordinate-drop idea and the unqualified squeeze.
- The completeness audit against the spec raised a finding:

  > **F2: V1 over-squeezed legitimate length-one sample dimensions.** *`.squeeze(drop=True)`
  > had no `dim` argument, so it would remove every length-one dimension … That would
  > remove `x` even though `sample_dims=["x"]` means `x` was not stacked and should be
  > preserved.*
  > — [`fvk/FINDINGS.md`](../results/verified031-codex-archlinux-20260616T140808Z/pydata__xarray-4094/fvk/FINDINGS.md#L22)

- The iteration guidance turned the finding into the code decision:

  > *"V1 should not stand unchanged because F2 violates PO4. V2 repairs F2 by replacing
  > unrestricted `.squeeze(drop=True)` with targeted squeezing."*
  > — [`fvk/ITERATION_GUIDANCE.md`](../results/verified031-codex-archlinux-20260616T140808Z/pydata__xarray-4094/fvk/ITERATION_GUIDANCE.md#L7)

- The decision log records the change and its provenance:

  > **Decision 2: Replaced V1's unrestricted `.squeeze(drop=True)`.** *Trace: F2 and
  > PO4/PO5/PO6 … V1 would also squeeze a legitimate length-one sample dimension, so V2
  > now computes `dims_to_squeeze` explicitly and squeezes only singleton consumed stacked
  > metadata … or single-null missing-level placeholders.*
  > — [`reports/fvk_notes.md`](../results/verified031-codex-archlinux-20260616T140808Z/pydata__xarray-4094/reports/fvk_notes.md#L15)

The causal chain is fully on the record:

```
INTENT item 5  ->  E5 (sample_dims are frame conditions) + E8 (audit: squeeze removes all size-1 dims)
               ->  F2 (V1 audit: length-1 sample dim erased)
               ->  PO4 (obligation: sample dimensions preserved)
               ->  ITERATION_GUIDANCE / Decision 2  ->  V2 patch
```

The resulting
[V2 patch](../results/verified031-codex-archlinux-20260616T140808Z/pydata__xarray-4094/solutions/solution_fvk.patch)
builds an explicit `dims_to_squeeze` list and squeezes only the consumed stacked dimension
(when singleton and not carrying a real level) and single-null missing-level placeholders:

```python
if dims_to_squeeze:
    data_array = data_array.squeeze(dim=dims_to_squeeze, drop=True)
data_dict[k] = data_array.drop_vars([dim, variable_dim], errors="ignore")
```

The `V1 -> V2` transition was driven by `F2`/`PO4`, **not** by a new failing test — no
test for a length-1 sample dimension exists anywhere in the suite (see §5).

## 5. Verification

**Harness (official SWE-bench Docker).** A regression test for the length-1 sample
dimension was run against all three patched trees
([baseline](../verified500_analysis/pydata__xarray-4094/enhanced_tests/_proof/baseline.report.json) →
**RED**,
[gold](../verified500_analysis/pydata__xarray-4094/enhanced_tests/_proof/gold.report.json) →
**RED**,
[fvk](../verified500_analysis/pydata__xarray-4094/enhanced_tests/_proof/fvk.report.json) →
**GREEN**).

**Behavioral demonstration.** A dataset whose variables share a length-1 dimension `x`:

```python
import numpy as np, xarray as xr
arr = xr.DataArray(np.arange(1), coords=[("x", [0])])   # length-1 'x' dimension
ds  = xr.Dataset({"a": arr, "b": arr})
roundtrip = ds.to_stacked_array("y", ["x"]).to_unstacked_dataset("y")
roundtrip.identical(ds)
```

| variant | reconstructed vars | `roundtrip.identical(ds)` |
|---|---|---|
| original / baseline / gold | `a()`, `b()` — **`x` dimension destroyed** (scalars) | **False** (data shape lost) |
| **fvk** | `a('x',)`, `b('x',)` — `x` preserved | **True** |

`x` carries a real coordinate value; collapsing it to a scalar is data loss, not
cosmetics. No regression: the targeted squeeze only fires on the consumed stacked
dimension or a single-null sentinel, so mixed-dimensional round trips that keep a real
stacked level are unchanged.

**FVK beat the human oracle.** Gold changed only the `sel(..., drop=True)` call but kept
the identical `.squeeze(drop=True)`, so gold reproduces the same length-1 data loss — the
harness confirms gold RED. FVK's per-dimension squeeze goes beyond what the maintainers
themselves shipped.

## 6. Boundaries & honesty

- **Severity: High.** This is a silent **data-shape / data-loss** defect — among the
  highest-stakes failure classes — and it survives in the maintainers' own gold patch. The
  trigger breadth is any round trip over a variable with a legitimate length-1 sample
  dimension; a user gets a scalar where they had a 1-element array, with no error. This is
  a strong "passing tests (and even the official fix) is not correctness" example.
- **Proof status: constructed, not machine-checked.** The K artifacts
  ([`mini-xarray-unstack.k`](../results/verified031-codex-archlinux-20260616T140808Z/pydata__xarray-4094/fvk/mini-xarray-unstack.k),
  [`to-unstacked-dataset-spec.k`](../results/verified031-codex-archlinux-20260616T140808Z/pydata__xarray-4094/fvk/to-unstacked-dataset-spec.k))
  and the `kompile`/`kprove` commands were *written but never run* — the FVK artifacts say
  so explicitly
  ([`fvk/PROOF.md`](../results/verified031-codex-archlinux-20260616T140808Z/pydata__xarray-4094/fvk/PROOF.md#L3)).
  We therefore claim **proof-structured reasoning**, not a machine-checked proof. The
  bug-detection value does not depend on the unrun `kprove`; the fix's correctness is
  independently confirmed by the harness RED→GREEN above.
- **Attribution.** The `V1 -> V2` iteration is documented across `FINDINGS.md`,
  `ITERATION_GUIDANCE.md`, and `fvk_notes.md`; the patch delta is observed directly from
  `solution_fvk.patch`. The constructed proof covers the issue family and the
  one-real-level mixed-dimensional case, not every hand-built MultiIndex shape — the FVK
  findings note this residual.

## Artifact map

| Claim | Source |
|---|---|
| Issue text, repro | [`_materials/problem_statement.md`](../verified500_analysis/pydata__xarray-4094/_materials/problem_statement.md#L1) |
| Baseline patch | [`solutions/solution_baseline.patch`](../results/verified031-codex-archlinux-20260616T140808Z/pydata__xarray-4094/solutions/solution_baseline.patch) |
| Baseline reasoning | [`reports/baseline_notes.md`](../results/verified031-codex-archlinux-20260616T140808Z/pydata__xarray-4094/reports/baseline_notes.md#L17) |
| FVK patch | [`solutions/solution_fvk.patch`](../results/verified031-codex-archlinux-20260616T140808Z/pydata__xarray-4094/solutions/solution_fvk.patch) |
| Gold patch | [`_materials/gold.patch`](../verified500_analysis/pydata__xarray-4094/_materials/gold.patch) |
| Intent (length-1 preservation) | [`fvk/INTENT_SPEC.md#L19`](../results/verified031-codex-archlinux-20260616T140808Z/pydata__xarray-4094/fvk/INTENT_SPEC.md#L19) |
| Evidence E5 (frame condition) | [`fvk/PUBLIC_EVIDENCE_LEDGER.md#L11`](../results/verified031-codex-archlinux-20260616T140808Z/pydata__xarray-4094/fvk/PUBLIC_EVIDENCE_LEDGER.md#L11) |
| Evidence E8 (squeeze audit) | [`fvk/PUBLIC_EVIDENCE_LEDGER.md#L14`](../results/verified031-codex-archlinux-20260616T140808Z/pydata__xarray-4094/fvk/PUBLIC_EVIDENCE_LEDGER.md#L14) |
| Obligation PO4 | [`fvk/PROOF_OBLIGATIONS.md#L26`](../results/verified031-codex-archlinux-20260616T140808Z/pydata__xarray-4094/fvk/PROOF_OBLIGATIONS.md#L26) |
| Finding F2 | [`fvk/FINDINGS.md#L22`](../results/verified031-codex-archlinux-20260616T140808Z/pydata__xarray-4094/fvk/FINDINGS.md#L22) |
| Iteration decision (V1→V2) | [`fvk/ITERATION_GUIDANCE.md#L7`](../results/verified031-codex-archlinux-20260616T140808Z/pydata__xarray-4094/fvk/ITERATION_GUIDANCE.md#L7) |
| Decision trace 2 | [`reports/fvk_notes.md#L15`](../results/verified031-codex-archlinux-20260616T140808Z/pydata__xarray-4094/reports/fvk_notes.md#L15) |
| Constructed K core | [`fvk/mini-xarray-unstack.k`](../results/verified031-codex-archlinux-20260616T140808Z/pydata__xarray-4094/fvk/mini-xarray-unstack.k), [`fvk/to-unstacked-dataset-spec.k`](../results/verified031-codex-archlinux-20260616T140808Z/pydata__xarray-4094/fvk/to-unstacked-dataset-spec.k) |
| Proof status (not machine-checked) | [`fvk/PROOF.md#L3`](../results/verified031-codex-archlinux-20260616T140808Z/pydata__xarray-4094/fvk/PROOF.md#L3) |
| Harness RED/GREEN verdicts | [`enhanced_tests/_proof/`](../verified500_analysis/pydata__xarray-4094/enhanced_tests/_proof/) |

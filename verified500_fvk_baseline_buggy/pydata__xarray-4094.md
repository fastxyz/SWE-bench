# pydata__xarray-4094

- **Verdict:** A_GENUINE_FIX — baseline (and the official human gold fix) use an unqualified `.squeeze(drop=True)` that silently destroys legitimate length-1 dimensions during a stack→unstack roundtrip; fvk uses a targeted per-dimension squeeze that preserves them.
- **Pitch-worthiness (1-5):** 5
- **Harness-verified regression test:** FAILS on baseline (RED), PASSES on FVK (GREEN), and FAILS on the official human fix (gold), via the official SWE-bench Docker harness.

## Benchmark Result

- Baseline arm: official SWE-bench evaluation marked the patch as resolved.
- FVK arm: official SWE-bench evaluation marked the patch as resolved.
- Audit category: baseline passed the benchmark but remained concretely buggy.

## The issue
`DataArray.to_unstacked_dataset()` is the inverse of `to_stacked_array()`. The reported bug: roundtripping a dataset through `to_stacked_array(...).to_unstacked_dataset(...)` raised / lost data for single-dimension variables. The fix must reconstruct each original variable by selecting its level out of the stacked array and dropping only the *stacked* index dimension.

## What baseline did
Baseline (and gold) reconstruct each variable with `data.sel(...).squeeze(drop=True)`. `squeeze()` with no `dim=` argument removes **every** size-1 dimension on the selection — which happens to also remove any *legitimate* length-1 sample dimension or real size-1 stacked level, not just the stacked index that should be dropped. It passes the reported test because that test's sample dimension has length ≥ 2.

## What fvk changed and why
fvk replaced the blanket `.squeeze(drop=True)` with a targeted drop of only the stacked dimension being unstacked (squeeze/select scoped to that single level dimension), leaving all other dimensions intact. `fvk_FINDINGS.md` flagged the unqualified squeeze as over-broad.

## FVK Formal Argument

- **FVK status:** constructed, not machine-checked.
- **FVK formal argument:** PO4/PO5/PO6: sample dimensions and real remaining stacked levels are frame conditions; only consumed coordinate metadata or missing stacked-level placeholders may be removed.
- **Why it catches baseline:** baseline uses unconstrained `squeeze(drop=True)`, so it can remove unrelated size-1 sample dimensions that the unstacking obligation says must be preserved.

## Concrete demonstration (executed, all variants)
```python
import numpy as np, xarray as xr
arr = xr.DataArray(np.arange(1), coords=[("x", [0])])      # a length-1 'x' dimension
ds  = xr.Dataset({"a": arr, "b": arr})
roundtrip = ds.to_stacked_array("y", ["x"]).to_unstacked_dataset("y")
roundtrip.identical(ds)
```

| variant | reconstructed vars | `roundtrip.identical(ds)` |
|---|---|---|
| **baseline** | `a()`, `b()` — **`x` dimension destroyed** (scalars) | **False** (data shape lost) |
| **gold (oracle)** | `a()`, `b()` — **`x` destroyed** | **False** (same bug) |
| **fvk** | `a('x',)`, `b('x',)` — `x` preserved | **True** ✅ |

fvk was verified to pass everything baseline/gold pass, **plus** 4 additional input families they get wrong (length-1 sample dims, real size-1 stacked levels, and the single-sample `y[0]` subcase).

## Why the tests missed it
`tests.json` FAIL_TO_PASS covers the reported MCVE, whose sample dimension has length ≥ 2 — so the unqualified squeeze removes only the intended stacked dimension and the bug is invisible. No test roundtrips a variable with a legitimate length-1 dimension. That is exactly why the **human gold fix shipped with the same latent bug**.

## FVK vs. Human Fix

**Human fix issue:** yes.

The human fix uses the same unqualified `squeeze(drop=True)` shape as baseline. FVK is stricter: it squeezes only dimensions justified by the unstacking invariant, so legitimate size-1 sample dimensions survive.

Gold uses the identical `.squeeze(drop=True)`. So fvk is **strictly more correct than the official human fix** on length-1 dimensions and size-1 real levels. **GOLD_MATCH: partial** (both fix the reported MCVE; fvk additionally fixes the latent over-squeeze).

## Confidence & caveats
- **High confidence:** all three variants executed; outputs and `identical()` results captured directly.
- This is a silent **data-shape/data-loss** defect — among the highest-stakes failure classes — and it survives in the maintainers' own patch, which makes it a strong "passing tests (and even the official fix) isn't correctness" example.

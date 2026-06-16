# FVK Spec

Status: constructed, not machine-checked. No tests, Python, or K tooling were
run.

## Scope

This FVK pass audits the V1 fix to `DataArrayRolling.__iter__` in
`repo/xarray/core/rolling.py`. The defect is localized to arithmetic slice
bounds for one-dimensional manual rolling iteration. The formal model therefore
abstracts one iterator position to a pure bound calculation:

`rollingBounds(N, W, center, I) -> pair(start, stop)`

where `N` is the dimension length, `W` is the rolling window size, and `I` is a
zero-based output position. Labels, `isel`, and `min_periods` masking are frame
conditions around these bounds.

## Intent Summary

The intent-only obligations are recorded in `fvk/INTENT_SPEC.md`; public
evidence is recorded in `fvk/PUBLIC_EVIDENCE_LEDGER.md`. The core requirement is
that manual iteration over `da.rolling(..., center=True)` yields center-justified
logical windows equivalent to direct centered rolling reductions.

## Contract

Preconditions:

- `N >= 0`
- `W > 0`
- For a yielded position, `0 <= I < N`
- `center` is interpreted as the boolean value stored in `self.center[0]`; false
  and `None` follow the non-centered path.

Postconditions:

- If `center` is false:
  `start = max(I - (W - 1), 0)` and `stop = min(I + 1, N)`.
- If `center` is true:
  `start = max(I - (W // 2), 0)` and
  `stop = min(I + ((W - 1) // 2) + 1, N)`.
- The iterator yields `(label, window)` where `label` is unchanged from
  `self.window_labels[I]`, and `window` is the original object sliced as
  `isel({dim0: slice(start, stop)})`, then masked by the existing
  `counts >= self.min_periods` rule.

## Formal Core

The formal K artifacts are:

- `fvk/mini-python-rolling.k`: minimal semantics for `rollingBounds`.
- `fvk/rolling-iter-spec.k`: reachability claims for centered, non-centered,
  and concrete issue-witness bounds.

Exact commands to machine-check later, intentionally not executed here:

```sh
cd fvk
kompile mini-python-rolling.k --backend haskell
kast --backend haskell rolling-iter-spec.k
kprove rolling-iter-spec.k
```

Expected outcome if machine-checked: `kprove` returns `#Top`.

## Adequacy

The English meaning of the K claims is in `fvk/FORMAL_SPEC_ENGLISH.md`; the
round-trip audit is in `fvk/SPEC_AUDIT.md`; public API compatibility is in
`fvk/PUBLIC_COMPATIBILITY_AUDIT.md`.

Adequacy verdict: PASS. The formal claims match public issue intent and the
existing `Variable.rolling_window` centering convention. They do not preserve the
reported legacy right-aligned centered behavior as a spec.

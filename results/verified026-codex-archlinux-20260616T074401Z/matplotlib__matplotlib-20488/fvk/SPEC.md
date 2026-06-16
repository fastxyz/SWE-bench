# FVK SPEC

Status: constructed, not machine-checked. No tests, Python, `kompile`, or
`kprove` were run.

## Scope

Target: the `LogNorm` temporary lower-limit repair in
`repo/lib/matplotlib/image.py`, inside `_ImageBase._make_image`, immediately
before `self.norm(resampled_masked)` is called.

The formal model abstracts the full NumPy image-resampling pipeline down to the
observable branch that matters for this issue:

```python
if isinstance(self.norm, mcolors.LogNorm):
    if s_vmin <= 0:
        s_vmin = max(s_vmin, np.finfo(scaled_dtype).eps)
```

The abstraction keeps the property under audit: whether the temporary lower
limit handed to `LogNorm` is strictly positive. It intentionally does not model
pixel interpolation, masked-array propagation, colormap lookup, renderer I/O, or
termination.

## Intent Spec

I1. Huge-range log-normalized images with finite positive user `vmin`/`vmax`
must not fail by handing `LogNorm` an invalid temporary lower limit after image
rescaling.

I2. For `LogNorm`, the temporary lower limit used for the log transform must be
strictly positive. A zero lower limit is invalid for the same reason a negative
lower limit is invalid.

I3. If the temporary lower limit is already positive, the image path must leave
it unchanged so existing color-boundary behavior is preserved.

I4. Non-`LogNorm` normalization paths are outside the reported bug and must keep
the same behavior.

I5. Invalid or non-finite caller-provided log limits are not part of the public
issue's intended success domain; the existing `LogNorm` validation should still
be allowed to reject them.

## Public Evidence Ledger

| ID | Source | Evidence | Semantic obligation | Status |
| --- | --- | --- | --- | --- |
| E1 | prompt | "`test_huge_range_log` is failing ... with a Value Error" | The image draw path should avoid the reported `ValueError` for the public huge-range log image. | Encoded by I1 and PO1. |
| E2 | prompt stack | `LogNorm.__call__` raises `ValueError("Invalid vmin or vmax")` after transforming `self.vmin` and `self.vmax`. | The temporary limits supplied by `_make_image` must be valid log-domain limits. | Encoded by I2 and PO2. |
| E3 | public test | `LogNorm(vmin=100, vmax=data.max())` with data containing `-1` and `1E20`. | A finite positive original `vmin` can be combined with nonpositive under-range data and a huge range without raising. | Encoded by I1 and PO3. |
| E4 | source comment | image.py says the resampled `vmin`/`vmax` are reset to account for small errors moving values in or out of range. | The local repair may adjust temporary limits to remain valid after round-trip error. | Encoded by PO4. |
| E5 | source code | Existing V0 special-cased `LogNorm` only when `s_vmin < 0`. | The intended special case already existed for negative limits; FVK audits whether zero belongs to the same invalid class. | Finding F1, discharged by PO3. |
| E6 | source code | `LogNorm` uses a log transform and rejects non-finite transformed limits. | `s_vmin == 0` is a real invalid-limit case, not a harmless boundary. | Encoded by PO2 and PO3. |

## Formal Model

Formal files:

- `fvk/mini-image-lognorm.k`: minimal K fragment for the guard.
- `fvk/image-lognorm-spec.k`: reachability claims for the repaired branch.

Mathematical abstraction:

- `S` is the finite temporary lower limit `s_vmin`.
- `EPS` is `np.finfo(scaled_dtype).eps`.
- `EPS > 0`.
- `adjustLogVmin(isLog, S, EPS)` models the source branch.

Claims in English:

C1. For `isLog == true` and `EPS > 0`, `adjustLogVmin(true, S, EPS) > 0`.

C2. For `isLog == true`, `EPS > 0`, and `S <= 0`, the result is `EPS`.

C3. For `isLog == true`, `EPS > 0`, and `S > 0`, the result is `S`.

C4. For `isLog == false`, the result is `S`.

## Adequacy Audit

The formal claims cover I1-I4 for the local failure mechanism reported by the
issue: a finite positive user `vmin` can become a non-positive temporary
`s_vmin` after huge-range round-trip scaling. C2 covers zero and negative
temporary limits. C3 and C4 cover frame conditions for already-valid log limits
and non-log norms.

The claims do not prove the whole renderer, all NumPy floating-point behavior,
masked arrays, or all invalid caller inputs. That is intentional and recorded as
Finding F5 in `fvk/FINDINGS.md` and residual risk R1 in
`fvk/ITERATION_GUIDANCE.md`.

## Public Compatibility Audit

No public function signature, method dispatch shape, return type, storage
format, or public API was changed. The edit is a comparison inside
`_ImageBase._make_image`; public callers and subclass overrides do not need any
update.

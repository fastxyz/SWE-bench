# Constructed Proof

Status: constructed, not machine-checked. No Python, tests, `kompile`, `kast`, or
`kprove` commands were run.

## Claims

The K-style claims are in `fvk/polyval-spec.k`, over the mini semantics in
`fvk/mini-xarray-polyval.k`.

Claim C1 proves `ensureNumeric(timedelta64, ...)`: each raw timedelta `td(T)` is
rewritten to numeric `n(T)`, modeling duration in nanoseconds from zero.

Claim C2 proves `ensureNumeric(datetime64, ...)`: each raw datetime `dt(T)` is
rewritten to numeric `n(T)`, where `T` is modeled as nanoseconds since the
1970-01-01 epoch.

Claim C3 proves numeric inputs pass through unchanged.

Claim C4 proves missing datetime-like values become `nan`.

Claim C5 proves `polyval` composes coordinate numericization with Horner
evaluation over the supplied coefficient map.

## Symbolic Proof Sketch

For PO1, symbolic execution enters `_ensure_numeric` and case-splits on
`x.dtype.kind`. In the `"m"` branch added by V1, the only call to
`datetime_to_numeric` supplies a timedelta offset, `np.timedelta64(0, "ns")`.
`datetime_to_numeric` first computes `array - offset`; because both operands are
timedelta-like, the subtraction is defined and preserves each duration. It then
divides by `np.timedelta64(1, "ns")`, yielding duration in nanoseconds, and maps
NaT to NaN. This discharges the reported failure mode: the proof path contains no
`timedelta64 - datetime64` operation.

For PO2, the `"M"` branch is textually the same epoch conversion behavior that
existed before V1, so datetime coordinates keep their existing numeric domain.

For PO3, if `x.dtype.kind` is neither `"m"` nor `"M"`, control reaches `return x`.
No conversion or copy is performed by `to_floatable`.

For PO4, after coefficient reindexing, the loop in `polyval` is Horner's method.
The invariant after processing degree `d` is that `res` represents the suffix
polynomial from degree `d` through `max_deg`. Initialization at `max_deg` makes
the invariant true for the highest coefficient. The body update
`res = res * coord + coeff[d]` extends the suffix by one lower degree. At
`d == 0`, the invariant is exactly the full polynomial
`sum(coeff[j] * coord ** j for j in 0..max_deg)`.

For PO5, `DataArray.copy(data=...)` changes only the data payload while keeping
the xarray wrapper structure, and `Dataset.map(to_floatable)` applies the same
per-variable conversion as before. Both datetime-like branches delegate missing
values to `datetime_to_numeric`, preserving its NaT-to-NaN behavior.

For PO6, the alternative proof attempt with `offset=None` for timedelta values
would choose the minimum timedelta as offset in `datetime_to_numeric`. That
produces values relative to the minimum coordinate and fails to match `polyfit`'s
raw timedelta float domain for coordinates that do not begin at zero. The V1 zero
offset discharges this obligation.

## Adequacy And Compatibility

`fvk/SPEC_AUDIT.md` compares the formal-English clauses against
`fvk/INTENT_SPEC.md`; all clauses pass with two explicit scope clarifications.
`fvk/PUBLIC_COMPATIBILITY_AUDIT.md` records no public signature or caller
compatibility break.

## Machine-Check Commands

These commands are recorded for a future environment with K installed. They were
not run in this benchmark session.

```sh
kompile fvk/mini-xarray-polyval.k --backend haskell
kast --backend haskell fvk/polyval-spec.k
kprove fvk/polyval-spec.k
```

Expected result after a real machine check: `kprove` returns `#Top` for all
claims. Until then, this proof remains constructed, not machine-checked.

## Test Guidance

No tests were run or edited. Because the proof was not machine-checked and hidden
tests are unavailable, there is no recommendation to remove tests. Useful public
tests to add in a normal development setting would cover a direct timedelta
`DataArray` coordinate, a nonzero-start timedelta coordinate, existing datetime
coordinates, and numeric coordinate pass-through.

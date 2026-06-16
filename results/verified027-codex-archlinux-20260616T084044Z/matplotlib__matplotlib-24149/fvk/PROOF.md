# Constructed Proof

Status: constructed, not machine-checked. The benchmark instructions prohibit
running Python, tests, `kompile`, or `kprove`, so this is a proof construction
and command record only.

## Commands Not Run

```sh
kompile fvk/mini-convert-dx.k --backend haskell
kast --backend haskell fvk/convert-dx-spec.k
kprove fvk/convert-dx-spec.k
```

Expected machine-check result after a real K run: `#Top` for all claims, subject
to the mini-semantics adequacy caveat in `SPEC_AUDIT.md`.

## Proof Sketch

### Representative Selection

Before V1, `_convert_dx` called `_safe_first_finite(x0)` and
`_safe_first_finite(xconv)` without handling the case where the generator search
had no finite element. On an all-NaN iterable, `_safe_first_finite` reaches
`next(val for val in obj if safe_isfinite(val))`; because no value satisfies
the predicate, Python raises `StopIteration`.

V1 adds a guarded fallback at both representative-selection sites:

- if `_safe_first_finite` succeeds, keep its first-finite value;
- if it raises `StopIteration`, use `cbook.safe_first_element` for that same
  sequence.

This discharges PO-001 and PO-003. The first branch preserves the older
leading-NaN fix; the second branch handles all-nonfinite data.

### Concrete Reproduction

For `ax.bar([np.nan], [np.nan])`, the x conversion path gives:

1. `x0 = [nan]`;
2. `xconv = array([nan])`;
3. `_safe_first_finite(x0)` raises `StopIteration`;
4. V1 chooses `safe_first_element(x0) == nan`;
5. `_safe_first_finite(xconv)` raises `StopIteration`;
6. V1 chooses `safe_first_element(xconv) == nan`;
7. scalar `width` is wrapped, converted with the selected representatives, and
   delisted back to a scalar.

In the mini semantics, this is claim `REPRO_SINGLE_NAN`:

```k
runConvertDx(dx(8) ; .Dxs, nan ; .Vals, nan ; .Vals)
  => widths(nan ; .Vals)
```

The important postcondition is not the numeric width value itself; it is that
the no-finite representative case reaches width data instead of
`stopIteration`. This discharges PO-002.

### Mixed Leading-NaN Preservation

For a sequence like `[nan, finite]`, `_safe_first_finite` succeeds. Because V1
only catches `StopIteration`, the successful result is still the finite
representative. In the mini semantics, claim
`MIXED_LEADING_NAN_KEEPS_FIRST_FINITE` rewrites the representative pair to
`finite(X0)` and `finite(X)`, not to the leading `nan` values. This discharges
PO-003.

### Empty Converted Coordinates

If `xconv.size == 0`, `_convert_dx` returns `convert(dx)` before any
representative selection. V1 does not edit that branch. In the mini semantics,
claim `EMPTY_XCONV_UNCHANGED` rewrites empty converted coordinates to
`converted(DXS)`. This discharges PO-004 and supports Finding F-003.

### Fallback and Shape Frame Conditions

The outer fallback for `ValueError`, `TypeError`, and `AttributeError` remains
unchanged, so PO-005 is discharged by source framing. The scalar/list `dx`
shape logic remains unchanged, so PO-006 is discharged by source framing plus
the scalar reproduction claim. No public signature or global `cbook` helper was
changed, so PO-007 is discharged by the compatibility audit.

## Residual Risk

- The proof is partial correctness only and constructed only.
- The mini semantics abstracts NumPy arrays and Matplotlib unit conversion into
  representative lists and a `delta` function. This is adequate for the
  `StopIteration` bug because the abstraction preserves whether representative
  selection succeeds or aborts, but it does not prove rendering, autoscaling, or
  backend behavior.
- No tests should be removed from this constructed proof. Integration and
  rendering tests remain necessary.

## Test Guidance

No tests were run or edited. After machine-checking and in a normal development
environment, useful tests would cover:

- `ax.bar([np.nan], [np.nan])` creates one rectangle and does not raise;
- `ax.bar([np.nan], [0])` does not raise;
- a leading-NaN sequence with later finite x values still creates bars,
  preserving the first-finite behavior.

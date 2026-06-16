# Constructed Proof

Status: constructed, not machine-checked. No `kompile`, `kast`, `kprove`,
Python, or Django tests were executed.

## Machine-Check Commands

These commands are recorded for a future environment with K installed:

```sh
kompile fvk/mini-floatformat.k --backend haskell
kast --backend haskell fvk/floatformat-spec.k
kprove fvk/floatformat-spec.k
```

Expected machine-check result after successful proof discharge: `#Top`.

## Proof Summary

The bug path is zero-valued Decimal formatting with precision `0`.

Let `S >= 0` be the Decimal scale, so a zero value such as `"0.00"` has
coefficient digit length `1` and exponent `-S`. Let `P >= 0` be the requested
precision. On the zero path, Django's raw pre-fix precision expression reduces
to:

```text
raw = P + 2 - S
```

For the reported input `"0.00"` with `S = 2` and `P = 0`, this gives `raw = 0`,
which violates Decimal's `prec >= 1` precondition.

V1 computes:

```text
prec = max(1, raw)
```

For all integers `raw`, `max(1, raw) >= 1`. Therefore Decimal context
construction no longer raises the reported `ValueError` for any zero scale
`S >= 0` and nonnegative precision `P`.

For the reported precision `P = 0`, quantizing zero at exponent `0` still
produces zero. The existing output construction suppresses a sign for rounded
zero and passes the integer-form string to `number_format(..., decimal_pos=0)`,
so the observable result is `"0"`.

For negative precision `P < 0`, the existing `if not m and p < 0` branch returns
`"0"` before the edited precision line. V1 does not affect that branch.

For all paths where `raw >= 1`, `max(1, raw) = raw`, so V1 preserves the old
precision used by the existing quantization path.

## Reachability Claims

- C-01: `<k> safePrec(P, S) </k>` reaches a precision value at least `1` for
  all `P >= 0` and `S >= 0`.
- C-02: `<k> floatformatZero(0, S) </k>` reaches `"0"` for all `S >= 0`.
- C-03: `<k> floatformatZeroNegative(P) </k>` reaches `"0"` for all `P < 0`.

There are no loop circularities in this audited slice.

## Residual Risk

This is a partial, constructed proof over a mini semantics, not a
machine-checked proof over full Python and Decimal semantics. Full
localization, grouping, nonzero rounding, float fallback, infinity, NaN, and
invalid argument parsing remain outside this proof and should keep their
conventional tests.

## Test-Redundancy Recommendation

No test deletion is recommended. Because the proof is not machine-checked and
the mini semantics covers only the reported precision path, all existing Django
tests should remain. New regression tests for F-04 would be appropriate outside
this benchmark's no-test-editing constraint.

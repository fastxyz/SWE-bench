# Constructed Proof

Status: constructed, not machine-checked. No `kompile`, `kast`, or `kprove`
command was run in this environment.

## Summary

The proof establishes partial correctness of the straight-line
`_format_float` selection and cleanup logic for the public issue domain:

- if Python's `str(value)` token fits in 20 characters, V1 selects it;
- otherwise V1 keeps the compact legacy `.16G` fallback;
- selected lowercase exponent markers are normalized to uppercase;
- the concrete issue value `0.009125` serializes as `0.009125`;
- the reported HIERARCH card formats with the full comment;
- unmodified parsed `_valuestring` cards are outside the changed path and are
  preserved.

There are no loops or recursive calls, so no circularity claim is needed.

## Symbolic execution sketch

For `formatFloat(floatView(S, Legacy))`, the mini semantics rewrites:

```text
formatFloat(floatView(S, Legacy))
=> formatToken(floatView(S, Legacy))
=> cap20(normalizeExponent(ensureDecimal(chooseBase(normalizeLowerE(S), Legacy))))
```

Case split on `lengthString(normalizeLowerE(S)) <= 20`:

1. Short branch:
   `chooseBase(normalizeLowerE(S), Legacy) => normalizeLowerE(S)`.
   By transitivity, the result is
   `cap20(normalizeExponent(ensureDecimal(normalizeLowerE(S))))`.
   This is claim `SHORT-REP-PREFERENCE`.
2. Fallback branch:
   `chooseBase(normalizeLowerE(S), Legacy) => Legacy`.
   By transitivity, the result is
   `cap20(normalizeExponent(ensureDecimal(Legacy)))`.
   This is claim `LEGACY-FALLBACK`.

For the reported value:

```text
S      = "0.009125"
Legacy = "0.009124999999999999"
lengthString(normalizeLowerE(S)) = 8 <= 20
normalizeLowerE(S) = "0.009125"
ensureDecimal("0.009125") = "0.009125"
normalizeExponent("0.009125") = "0.009125"
cap20("0.009125") = "0.009125"
```

Therefore `formatFloat(floatView(S, Legacy)) => "0.009125"`, discharging
`REPORTED-FLOAT`.

For the reported card, `formatHierarchRadius` concatenates the HIERARCH keyword,
the proven token, and the comment. `pad80` then pads the 76-character concrete
card image with four spaces, yielding:

```text
HIERARCH ESO IFM CL RADIUS = 0.009125 / [m] radius arround actuator to avoid    
```

The image length is 80, so no truncation branch is reached in the modeled
observable.

## Source-level frame proof

`Card._format_value()` has a pre-existing branch:

```python
elif (
    self._valuestring
    and not self._valuemodified
    and isinstance(self.value, float_types)
):
    value = f"{self._valuestring:>20}"
```

The V1 edit is inside `_format_float`, which this branch does not call.
Therefore parsed, unmodified float/complex value strings remain preserved.

## Machine-check commands

These are emitted for later checking only.

```sh
kompile fvk/mini-fits-card-format.k --backend haskell
kast --backend haskell fvk/fits-card-format-spec.k
kprove fvk/fits-card-format-spec.k
```

Expected machine-check result, if the mini semantics and claims parse as
written: `#Top` for all claims.

## Test guidance

Do not remove tests based on this constructed proof. If machine-checked later,
point tests for `_format_float(0.009125)` and the reported HIERARCH card would
be subsumed by `REPORTED-FLOAT` and `REPORTED-HIERARCH-CARD`; integration,
I/O, parser, verifier, and regression tests should remain.

## Residual risk

- The proof is constructed, not machine-checked.
- The mini semantics abstracts Python's float-to-string implementations as
  supplied string views; it verifies the patch's selection and normalization
  logic, not Python's float conversion internals.
- Termination is trivial for the straight-line modeled helper path and no
  separate total-correctness argument is needed.

# Constructed Proof

Status: constructed, not machine-checked. Per task constraints, no tests,
Python, `kompile`, or `kprove` were executed.

## Formal Files

- Semantics: `fvk/mini-unsigned-coder.k`
- Claims: `fvk/unsigned-integer-coder-spec.k`

## Commands To Machine-Check Later

Do not treat these as executed in this task.

```sh
kompile fvk/mini-unsigned-coder.k --backend haskell
kast --backend haskell fvk/unsigned-integer-coder-spec.k
kprove fvk/unsigned-integer-coder-spec.k
```

Expected machine-check result after a real run: `#Top` for all stated claims.

## Proof Sketch

The mini semantics represents the observable state of
`UnsignedIntegerCoder.decode`: dtype kind, itemsize, data values, optional fill
value, `_Unsigned` marker in attrs, marker in encoding, and warning state.

For absent `_Unsigned`, the `decode` rule takes the absent-marker branch. It
does not call the target-kind or cast functions. The post-state is identical for
the modeled fields, discharging CLAIM-ABSENT-UNSIGNED.

For integer data with a present marker, symbolic execution first evaluates the
marker predicates. PO1 splits into four converting cases: signed plus unsigned
marker for `"true"` and `True`, and unsigned plus signed marker for `"false"`
and `False`. In each case the target-kind function chooses the opposite dtype
kind with the same itemsize. The cast functions are applied to values and fill
with the same target kind and itemsize, discharging PO2 and PO3.

For integer data whose marker does not request opposite signedness, the
`shouldConvert` predicate is false. The no-op integer claim moves `_Unsigned`
from attrs to encoding but leaves dtype, values, fill, and warning state
unchanged.

For non-integer data with `_Unsigned`, symbolic execution takes the
non-integer warning branch. No cast function is applied; the warning state
records `warnUnsignedNonInteger`, discharging PO5.

The source-level composition proof then follows the `decode_cf_variable` order:
`UnsignedIntegerCoder.decode` executes before `CFMaskCoder.decode`, so any data
and `_FillValue` conversion is visible to the later mask step. This discharges
PO4 for the issue's masked-and-scaled output.

## Adequacy Gate

`fvk/FORMAL_SPEC_ENGLISH.md` paraphrases every nontrivial claim.
`fvk/SPEC_AUDIT.md` compares those claims against the intent-only obligations in
`fvk/INTENT_SPEC.md`. The V1 string-only false marker failed the adequacy gate;
V2 passes it by accepting explicit boolean `False`.

## Test Guidance

No tests were run and no tests were edited.

Recommended tests to add or keep until machine-checking is performed:

- unsigned byte data with `_Unsigned="false"` decodes `128, 255` to `-128, -1`;
- unsigned byte data with `_Unsigned=False` decodes the same way;
- signed byte data with `_Unsigned="true"` and `_Unsigned=True` still decodes to
  unsigned values;
- `_FillValue` is converted to the same target dtype before masking;
- non-integer data with `_Unsigned` still warns.

No test deletion is recommended from this constructed proof.

## Residual Risk

This is a partial-correctness proof over a mini semantics, not a proof of the
entire Python/xarray/NumPy runtime. The trusted base is the adequacy of the
abstraction, NumPy's dtype-cast semantics, K reachability logic, and future
`kprove` execution.

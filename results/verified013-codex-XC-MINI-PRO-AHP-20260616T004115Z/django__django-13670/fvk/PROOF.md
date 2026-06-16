# FVK Proof

Status: constructed, not machine-checked.

## Claim

For every supported Python `datetime` year `Y` with `1 <= Y <= 9999`,
`DateFormat.y()` returns the two-digit decimal representation of `Y % 100`.

In the K model this is:

```text
dateformatY(Y) => digits2((Y modInt 100) /Int 10,
                          (Y modInt 100) modInt 10)
```

`digits2(T, O)` denotes the concrete two-character string formed from decimal
digits `T` and `O`.

## Formal Core

The constructed formal files are:

- `fvk/mini-python-dateformat.k`
- `fvk/dateformat-y-spec.k`

Exact commands for a future machine check, not executed in this session:

```sh
cd fvk
kompile mini-python-dateformat.k --backend haskell
kast --backend haskell dateformat-y-spec.k
kprove dateformat-y-spec.k
```

Expected machine-check result after a successful run: `#Top`.

## Symbolic Proof Sketch

1. Start with an arbitrary year `Y` satisfying `1 <= Y <= 9999`.
2. The V1 source expression is `'%02d' % (self.data.year % 100)`.
3. Substitute `Y` for `self.data.year`, producing `'%02d' % (Y % 100)`.
4. Integer modulo by `100` yields `R = Y % 100`, with `0 <= R <= 99` for all
   in-domain `Y`.
5. Width-two decimal formatting of any `R` in `0..99` yields exactly two digit
   positions: `R // 10` and `R % 10`.
6. Therefore the result is `digits2(R // 10, R % 10)`, equivalent to the
   required two-character string for the last two year digits.

There are no loops or recursive calls in this proof target. The proof is a
straight-line reachability proof by symbolic execution of modulo followed by
the `pad2` formatting rule.

## Boundary Case Discharge

- `1 <= Y <= 9`: `Y % 100 == Y`, tens digit is `0`, ones digit is `Y`; output
  is `"0Y"`.
- `10 <= Y <= 99`: `Y % 100 == Y`; output is the already two-digit year.
- `100 <= Y <= 999`: `Y % 100` drops all but the last two digits; output is
  still width two. For `Y = 123`, output is `"23"`.
- `1000 <= Y <= 9999`: the same modulo rule preserves the last two digits. For
  `Y = 1000`, output is `"00"`; for `Y = 1979`, output is `"79"`.

These cases discharge OBL-002 through OBL-005 and resolve F-001 through F-003.

## Compatibility Proof

The source diff changes only `DateFormat.y()` and preserves:

- the method signature,
- the fact that `y()` returns a string-like formatter result,
- the `DateFormat.Y()` implementation,
- `Formatter.format()` dispatch and escaping mechanics,
- all other date/time format specifiers.

This discharges OBL-006 and OBL-007 and resolves F-004.

## Residual Risk

The proof is constructed but not machine-checked. The trusted base is the
mini-K semantics for this expression and the abstraction of Python `%02d`
formatting as `pad2()`. This is recorded as F-005 and OBL-008.

## Test Redundancy Recommendation

No test files were modified. If the K proof is machine-checked in the future,
unit tests that assert in-domain point examples for `DateFormat.y()` are
logically subsumed by OBL-003, but retaining them is still reasonable as
integration coverage for Django's real Python runtime and formatting dispatch.

Recommended tests to add in normal development, not in this benchmark task:

- `dateformat.format(datetime(123, 4, 5, 6, 7), "y") == "23"`
- `dateformat.format(datetime(9, 1, 1), "y") == "09"`
- `dateformat.format(datetime(100, 1, 1), "y") == "00"`

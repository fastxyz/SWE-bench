# FVK Proof

Status: constructed, not machine-checked. No tests, Python, or K tooling were
run.

## Claims Proven Constructively

1. For every first name part `B + D` where `B` is a non-empty run of Unicode
   word characters excluding digits and underscore, and `D` is a non-empty run
   of ASCII digits, V1 `split_super_sub` returns `(B, [], [D])`.
2. The motivating case `ω0` therefore produces the subscript component `["0"]`.
3. Unicode pretty printing consumes that component and renders `0` as `₀`,
   producing `ω₀`.
4. ASCII multi-digit suffixes such as `x10` continue to split as `("x", [],
   ["10"])`.
5. Explicit separator behavior for `_`, `^`, and `__` is unchanged.

## Source-Level Symbolic Proof

For an input with no explicit `_`, `^`, or `__` separator, the scan in
`split_super_sub` sets `name` to the whole input and leaves `supers` and `subs`
empty. This applies to the issue input `ω0`.

V1 then evaluates `_name_with_digits_p.match(name)`. The pattern
`^([^\W\d_]+)([0-9]+)$` has two capture groups. The first group is exactly
`BaseRun`: Python `\w` minus Python `\d` minus `_`. The second group is an ASCII
digit run. For `ω0`, `ω` satisfies `BaseChar`, and `0` satisfies `DigitRun`, so
the match captures `("ω", "0")`.

When a match exists, the code executes:

```python
name, sub = m.groups()
subs.insert(0, sub)
```

So the post-state is `name == "ω"`, `supers == []`, and `subs == ["0"]`. This
discharges PO-1 and PO-2.

The unicode pretty-printer calls `pretty_symbol`, which calls
`split_super_sub`, translates the base name, and maps each subscript string
through the `sub` table. `sub["0"]` is the Unicode subscript zero. Therefore
`pretty_symbol("ω0")` renders `ω₀`, discharging PO-5.

For `x10`, the first group cannot consume `1` because digits are excluded from
`[^\W\d_]`. The only full match has base `x` and digit suffix `10`, so the
multi-digit suffix is preserved as one subscript run. This discharges PO-3 and
rules out the direct greedy `^(\w+)([0-9]+)$` alternative.

For explicit separators, the V1 diff does not touch the scan loop. Names such
as `x_1`, `x_1^aa`, and `beta_13_2` are split before the implicit digit
exception is considered. This frames the prior behavior and discharges PO-6.

## Formal-Core Artifacts

The corresponding constructed K-style core is:

- `fvk/mini-symbol-conventions.k`
- `fvk/symbol-conventions-spec.k`

These model the property-bearing part of the code: `BaseRun`, `DigitRun`,
concatenation, and the split result.

## Commands Not Executed

```sh
cd fvk
kompile mini-symbol-conventions.k --backend haskell
kast --backend haskell symbol-conventions-spec.k
kprove symbol-conventions-spec.k
```

Expected result after a successful future machine check: `kprove` returns
`#Top`. This was not attempted here.

## Test Recommendation

Do not remove tests. Existing ASCII tests that exercise the implicit
letter-plus-digit behavior are conditionally subsumed by the constructed proof
only after a successful machine check. A future non-benchmark change should add
public tests for `split_super_sub("ω0")` and unicode pretty printing of
`Symbol("ω0")`, but this task forbids modifying tests.

## Residual Risk

The proof relies on the stated Python 3 Unicode regex semantics for `\w` and
`\d`; it does not execute Python or K. It proves partial correctness for the
specified parser path and consumer behavior, not every behavior of SymPy's
printing subsystem.

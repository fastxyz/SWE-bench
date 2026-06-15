# Constructed Proof

Status: constructed, not machine-checked. No `kompile`, `kast`, `kprove`,
Python, or tests were run.

## Formal Artifacts

- Semantics: `fvk/mini-cds-units.k`
- Claims: `fvk/cds-parser-spec.k`

Machine-check commands for a later environment with K installed:

```sh
kompile fvk/mini-cds-units.k --backend haskell
kast --backend haskell fvk/cds-parser-spec.k
kprove fvk/cds-parser-spec.k
```

Expected machine-check result after a valid K run: `#Top`.

## What Is Proved

Partial correctness of the CDS parser semantic actions for the audited unit
grammar fragment:

1. Chained right-recursive divisions use the flattened denominator tail.
2. `10+3J/m/s/kpc2` parses to `1000 J / (m s kpc2)`.
3. `10-7J/s/kpc2` parses to `1e-7 J / (s kpc2)`.
4. Parentheses reset the division tail and preserve explicit grouping.
5. Ordinary one-slash division remains unchanged.
6. The final parser result unwraps the actual unit and does not expose the
   helper tail.

The proof is over parser reductions, not parser termination or the full Astropy
unit algebra.

## Symbolic Proof Sketch

Define each parser semantic value as `sem(actual, tail)`.

Base unit expression:

```text
unit(U) -> sem(U, U)
```

This discharges PO-1 for atomic units: an atom's standalone value and denominator
tail are the same unit.

Parenthesized expression:

```text
paren(C) -> sem(actual(C), actual(C))
```

This discharges PO-3. Parentheses make `C` atomic to surrounding operations, so
an outer slash divides by `actual(C)`, not by a flattened internal tail.

Product:

```text
prod(E, C) -> sem(actual(E) * actual(C), tail(E) * tail(C))
```

This discharges PO-4 by structural composition. Product preserves standalone
unit multiplication while also accumulating every factor that must be included
when the whole product appears in a denominator tail.

Division:

```text
div(E, C) -> sem(actual(E) / tail(C), tail(E) * tail(C))
```

This is the critical obligation PO-2. The actual unit divides by the right
operand's flattened tail, so nested right-recursive slash trees do not invert
later denominator factors back into the numerator.

Main result:

```text
main(C)      -> actual(C)
scaled(S,C) -> S * actual(C)
dexed(C)    -> dex(actual(C))
```

This discharges PO-5: final parser results use the actual unit only.

## Concrete Claim C1

For `10+3J/m/s/kpc2`, the parser tree is:

```text
scaled(p1000, div(unit(J), div(unit(m), div(unit(s), unit(kpc2)))))
```

Reduction from the inside out:

```text
evalC(unit(kpc2)) = sem(kpc2, kpc2)
evalC(div(unit(s), unit(kpc2)))
  = sem(s / kpc2, s * kpc2)
evalC(div(unit(m), div(unit(s), unit(kpc2))))
  = sem(m / (s * kpc2), m * s * kpc2)
evalC(div(unit(J), div(unit(m), div(unit(s), unit(kpc2)))))
  = sem(J / (m * s * kpc2), J * m * s * kpc2)
evalMain(scaled(p1000, ...))
  = p1000 * (J / (m * s * kpc2))
```

This reaches the expected unit and removes the pre-fix symptom where `s` moved
to the numerator.

## Concrete Claim C2

For `10-7J/s/kpc2`, the parser tree is:

```text
scaled(p1em7, div(unit(J), div(unit(s), unit(kpc2))))
```

Reduction:

```text
evalC(div(unit(s), unit(kpc2))) = sem(s / kpc2, s * kpc2)
evalC(div(unit(J), div(unit(s), unit(kpc2))))
  = sem(J / (s * kpc2), J * s * kpc2)
evalMain(scaled(p1em7, ...))
  = p1em7 * (J / (s * kpc2))
```

This reaches the expected unit and removes the pre-fix symptom where `kpc2`
moved to the numerator.

## Parentheses Claim C3

For `J/(m/s)`, the grouped denominator is represented as:

```text
div(unit(J), paren(div(unit(m), unit(s))))
```

The inner division has actual `m / s` and tail `m * s`, but `paren(...)`
rewrites to `sem(m / s, m / s)`. The outer division therefore reaches:

```text
J / (m / s)
```

This proves the fix does not over-flatten explicit grouping.

## Existing Behavior Claim C4

For `km/s`:

```text
evalC(div(unit(km), unit(s))) = sem(km / s, km * s)
evalMain(main(...)) = km / s
```

The actual unit is unchanged for ordinary one-slash CDS expressions.

## Proof-Derived Findings

No unresolved code finding remains. The only residual caveat is proof status:
the proof was constructed but not machine-checked. This caveat does not justify
withholding the V1 fix because the algebraic derivation discharges the public
intent obligations.

## Test Guidance

No tests were edited. After machine-checking, add or keep tests covering:

- `u.Unit("10+3J/m/s/kpc2", format="cds") == u.Unit("1000 J/(m s kpc2)")`
- `u.Unit("10-7J/s/kpc2", format="cds") == u.Unit("1e-7 J/(s kpc2)")`
- table reading through `format="ascii.cds"` for the MRT snippet from the issue
- a parenthesized grouping case such as `J/(m/s)`
- existing one-slash examples such as `km/s` and `[cm/s2]`

Any test-removal recommendation is conditional on running the K commands and
the normal Astropy test suite in a real execution environment.

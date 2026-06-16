# FVK Proof

Status: constructed, not machine-checked. No tests, Python, `kompile`, or
`kprove` were run.

## What Is Proved

For the audited `Mod.eval` path:

1. If optional polynomial common-factor extraction raises `PolynomialError`,
   `Mod.eval` catches it, sets `G = S.One`, keeps `p` and `q` unchanged, and
   continues toward symbolic `Mod` construction.
2. If `gcd(p, q)` succeeds, the previous simplification branch is preserved.
3. Modulo-by-zero behavior remains outside the catch and still raises
   `ZeroDivisionError`.

This is a partial-correctness proof over the scoped construction path. It does
not prove termination of the broader SymPy assumption engine, and it does not
define new branchwise `gcd` behavior for `Piecewise`.

## K Artifacts

The formal core is:

- `fvk/mini-sympy-mod.k`: a minimal semantics for the relevant `Mod.eval`
  control edge.
- `fvk/mod-spec.k`: K reachability claims for the success, polynomial-error
  fallback, and zero-divisor paths.

The mini-semantics abstracts SymPy expressions but keeps the property under
verification visible: `PolynomialError` from optional `gcd` extraction either
escapes as `polynomialError` or is converted into `symbolicMod(P, Q, one)`.

## Constructed Proof Sketch

### Claim `MOD-GCD-POLYERR`

Initial symbolic state:

```text
modEval(P, Q, gcdPolynomialError)
```

with side conditions:

```text
not isZeroDivisor(Q)
not hasEarlyResult(P, Q)
```

Symbolic execution:

1. `modEval` cannot take the zero-divisor rule because the side condition says
   `Q` is not a zero divisor.
2. No earlier direct evaluation is available, so execution reaches the
   post-`doit`/pre-`gcd` state.
3. The `gcdPolynomialError` branch models the V1 `except PolynomialError` edge.
   The state rewrites to `afterGcd(P, Q, one)`.
4. `afterGcd(P, Q, one)` rewrites to `symbolicMod(P, Q, one)`.

Postcondition:

```text
symbolicMod(P, Q, one)
```

No `polynomialError` state is reachable on this claim. This discharges PO-001
and PO-004.

### Claim `MOD-GCD-OK`

Initial symbolic state:

```text
modEval(P, Q, gcdOk(G))
```

under the same nonzero and no-early-result side conditions.

Symbolic execution follows the same prefix but takes the successful extraction
edge, rewriting to `afterGcd(P, Q, G)` and then to `symbolicMod(P, Q, G)`. This
models preservation of the original successful simplification branch and
discharges PO-002.

### Claim `MOD-ZERO-DIVISOR`

Initial symbolic state:

```text
modEval(P, Q, GO)
```

with side condition:

```text
isZeroDivisor(Q)
```

The first rule rewrites directly to `zeroDivisionError`, before any `gcd` state
can be reached. This discharges PO-003.

## Source-Level Argument

The V1 patch places the `try` block exactly around:

```python
G = gcd(p, q)
if G != 1:
    p, q = [
        gcd_terms(i/G, clear=False, fraction=False) for i in (p, q)]
```

and handles only:

```python
except PolynomialError:
    G = S.One
```

Because Python evaluates the right-hand side of `p, q = ...` before assigning to
`p` or `q`, a `PolynomialError` from either `gcd` or the list comprehension does
not partially update those variables. The subsequent code sees the original
`p`, original `q`, and `G = S.One`, which is the specified fallback.

The zero-divisor check and all earlier direct-evaluation branches occur before
this `try` block. They are outside the catch and therefore preserved.

## Machine-Check Commands

These commands were not run in this task. They are the constructed commands a
human could run later in an environment with K installed:

```sh
cd fvk
kompile mini-sympy-mod.k --backend haskell
kast --backend haskell mod-spec.k
kprove mod-spec.k
```

Expected machine-check result, if the mini-semantics and claims parse and
discharge: `#Top`.

## Test Guidance

No tests were run or edited. Because the proof is constructed but not
machine-checked, no existing test should be removed on the basis of this audit.

Tests that would be useful in the fixed test suite:

- Direct `Mod`/`%` construction for `(Piecewise((x, y > x), (y, True)) / z) % 1`
  should not raise `PolynomialError`.
- The reported `exp(sinh(Piecewise(...) / z)).subs({1: 1.0})` path with real
  symbols should not raise `PolynomialError`.
- Existing `Mod` simplification cases with successful `gcd` extraction should
  continue to produce the same forms.


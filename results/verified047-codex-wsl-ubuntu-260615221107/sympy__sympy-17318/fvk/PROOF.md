# Constructed Proof - sympy__sympy-17318

Status: constructed, not machine-checked. No `kompile`, `kast`, `kprove`,
Python, or tests were run.

## Formal Core

The formal core is in:

- `fvk/mini-sympy-surd.k`
- `fvk/sympy-surd-spec.k`

The mini-semantics abstracts SymPy expressions into the predicates needed by
the changed branch logic: additive shape, square-root depth, positive rational
squares, `Pow(..., S.Half)` detection, and tuple return shape.

## Proof Sketch

### PO1: `_sqrt_match(4 + I)`

For the issue representative `4 + I`, the squared addends are `16` and `-1`.
Both are rational, but `-1` is not positive. Therefore the strengthened guard

`all(sq.is_Rational and sq.is_positive for sq in sqargs)`

is false, so the `split_surds` fast path cannot fire. The remaining branch sorts
the addends and computes square-root depths. Both depths are `0`, so the maximum
depth is `0` and `_sqrt_match` returns `[]`. `_sqrtdenest1` treats an empty match
as "cannot denest" and returns the original expression. This removes the
pre-fix path to `_split_gcd()`.

### PO2: `split_surds` no-surd input

`split_surds` now collects only terms satisfying:

`x[1].is_Pow and x[1].exp == S.Half`

For `4 + I` and `1 + cbrt(2)`, no term satisfies that predicate. The new
explicit guard returns `(S.One, S.Zero, expr)` before `_split_gcd` is called.
Thus the no-surd case is total and source-local.

### PO3: `_split_gcd` empty input

The private helper now has a neutral empty case:

`_split_gcd() == (S.One, [], [])`

For non-empty input the previous code is unchanged: initialize `g = a[0]`,
place it in `b1`, then partition later values according to whether their gcd
with the running `g` is `1`. Existing non-empty behavior is preserved.

### PO4: `rad_rationalize` no-surd stop

For additive `den`, `rad_rationalize` calls `split_surds(den)`. If the result
has `a == 0`, the new guard returns `(num, den)` immediately. Because this
return occurs before the conjugate transformation and recursive call, both
`rad_rationalize(1, 4 + I)` and `rad_rationalize(1, 1 + cbrt(2))` stop.

### PO5: valid square-root rationalization

For `den = sqrt(2) + I`, `sqrt(2)` is a `Pow` with exponent `S.Half`, so it is
still collected. `I` is not collected as a square-root surd and remains in the
`b` part. The split is the same shape as before: `g = 2`, `a = 1`, `b = I`.
The conjugate step computes:

`num' = (sqrt(2) - I) * 1`

`den' = (sqrt(2))**2 - I**2 = 2 - (-1) = 3`

Since `3` is not additive, the next recursive call returns
`(sqrt(2) - I, 3)`. This preserves the public expected behavior.

### PO6: compatibility

The changed functions keep the same names, positional parameters, and return
tuple arities. The non-test source search found `_split_gcd` used by
`polys/numberfields.py`; that caller checks that a non-empty surd suffix exists
before calling `_split_gcd`, so the new empty helper case is not a behavior
change there.

### PO7: no bare exception handling

The diff adds predicate checks and early returns. It introduces no `try`,
`except`, or bare exception swallowing.

## Machine Check Commands

These commands are required to machine-check the constructed proof later. They
were not run in this session.

```sh
kompile fvk/mini-sympy-surd.k --backend haskell
kast --backend haskell fvk/sympy-surd-spec.k
kprove fvk/sympy-surd-spec.k
```

Expected machine-check result after a valid K setup: `#Top` for the claims in
`sympy-surd-spec.k`.

## Test Recommendation

No tests were modified. Tests covering the reported `sqrtdenest` traceback,
`rad_rationalize(1, 4 + I)`, `rad_rationalize(1, 1 + cbrt(2))`, and
`rad_rationalize(1, sqrt(2) + I)` should be kept or added unless and until the
K proof is machine-checked. No test removal is recommended from this
constructed-only proof.

## Residual Risk

The proof is partial correctness over an abstract mini-semantics. It does not
prove all SymPy expression normalization or termination behavior. The Findings
report does not depend on machine checking, but proof confidence and any test
removal remain conditioned on running the emitted K commands.

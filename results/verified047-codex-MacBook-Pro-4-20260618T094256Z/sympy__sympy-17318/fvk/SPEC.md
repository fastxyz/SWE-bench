# FVK Spec

Status: constructed, not machine-checked.

## Audited Units

### `_sqrt_match(p)`

Intent-derived contract:

- For an additive expression whose addends do not all have rational positive
  squares, `_sqrt_match` returns no match (`[]`) and does not call
  `split_surds`.
- The public witness is the radicand `4 + I`: `4**2` is positive rational, but
  `I**2` is rational non-positive, so the expression is not a regular real
  square-root surd sum.
- For supported real-surd sums, the existing `split_surds` path remains
  available.

Implementation fact used in the model:

- V1 computes `sqargs = [x**2 for x in pargs]` and requires every square to be
  both rational and positive before calling `split_surds`.

### `split_surds(expr)`

Intent-derived contract:

- For a sum containing supported explicit square-root powers, return the same
  3-tuple shape `(g, a, b)` as before.
- For a sum containing no supported explicit square-root power, return
  `(1, 0, expr)` and do not call `_split_gcd`.
- `_split_gcd` remains a non-empty-list helper; the guard belongs in
  `split_surds`.

Implementation fact used in the model:

- V1 collects only `Pow(..., S.Half)` terms and checks `if not surds` before
  `_split_gcd(*surds)`.

### `rad_rationalize(num, den)`

Intent-derived contract:

- If `den` is not an Add, return `(num, den)`.
- If `den` is an Add but `split_surds` finds no square-root component, return
  `(num, den)` without recursive progress.
- If `den` contains a supported square-root component, preserve the existing
  rationalization path.

Implementation fact used in the model:

- V1 multiplies `a` by `sqrt(g)` and returns `(num, den)` when `not a`.

## Mirrored Evidence Ledger

- E1-E3 justify the no-exception/no-match behavior for `4 + I`.
- E4-E5 justify guarding `split_surds` to regular square-root surds and guarding
  the empty-surd case.
- E6-E7 justify `rad_rationalize` no-op behavior for unsupported denominators.
- E8-E10 are regression frame conditions for supported square-root behavior.
- E11 identifies the concrete helper precondition that V1 must enforce.
- E12 supports keeping signatures and return shapes unchanged.

## Model Adequacy Boundary

The K model is a finite, source-level abstraction of the public issue examples
and directly touched helper branches. It preserves the observable distinctions
that matter for this audit:

- supported square-root term present vs absent;
- rational positive square vs rational non-positive square;
- no-op result vs rationalized result;
- tuple/list return shape;
- no recursive progress on unsupported denominators.

The model intentionally does not encode the full SymPy expression lattice,
sorting/canonicalization, or every denesting algorithm. Those are residual
engineering risks, not findings that force a V1 source edit in this audit.

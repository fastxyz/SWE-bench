# Constructed Proof

Status: constructed, not machine-checked. No tests, Python, `kompile`, `kast`,
or `kprove` were run.

## Claims Proved in the Mini Semantics

The formal artifacts are:

- `fvk/mini-python-vector.k`
- `fvk/vector-add-spec.k`

The claims are `ADD-ZERO-RIGHT`, `PY-ADD-ZERO-LEFT`,
`VECTOR-VECTOR-ADD`, `MUL-ZERO-VECTOR`, `SUM-REPRODUCER`, and
`NONZERO-SCALAR-REJECT`.

## Proof Sketch

`ADD-ZERO-RIGHT`: Starting from `vectorAdd(Vec(Cs), 0)`, the scalar-zero
addition rule rewrites directly to `Vec(Cs)`. This corresponds to V1's early
branch before `_check_vector()`.

`PY-ADD-ZERO-LEFT`: Starting from `pyAdd(0, Vec(Cs))`, the Python-dispatch rule
rewrites to `vectorAdd(Vec(Cs), 0)`. `ADD-ZERO-RIGHT` then rewrites that state
to `Vec(Cs)`. This models `sum()`'s initial `0 + vector` path through
`__radd__ = __add__`.

`VECTOR-VECTOR-ADD`: Starting from `vectorAdd(Vec(Cs), Vec(Ds))`, the vector
addition rule rewrites to `Vec(merge(Cs, Ds))`. V1 does not intercept this path
because the right operand is already a `Vector`.

`MUL-ZERO-VECTOR`: Starting from `mul(0, Vec(Cs))`, the zero multiplication rule
rewrites to `Vec(.Comps)`, the modeled `Vector(0)`.

`SUM-REPRODUCER`: Starting from `sum2(Vec(Cs), mul(0, Vec(Cs)))`, `sum2`
rewrites to a left fold from scalar `0`. The first addition reduces by
`PY-ADD-ZERO-LEFT` to `Vec(Cs)`. The second operand reduces by
`MUL-ZERO-VECTOR` to `Vec(.Comps)`. Vector-plus-vector addition then produces
`Vec(merge(Cs, .Comps))`, and the merge-unit rule reduces it to `Vec(Cs)`.

`NONZERO-SCALAR-REJECT`: Starting from `vectorAdd(Vec(Cs), I)` with
`I =/=Int 0`, the nonzero integer rule rewrites to `TypeError`. This models V1
falling through to unchanged `_check_vector()`.

## Why V1 Stands

The proof obligations cover the full public intent slice: scalar-zero addition,
reflected addition for `sum()`, zero-vector construction from `0 * vector`,
unchanged vector-plus-vector behavior, and unchanged rejection of nonzero
non-vector operands. The adequacy audit has no failed or ambiguous required
behavior, and the compatibility audit identifies no unhandled public signature,
callsite, or helper-contract change.

## Residual Risk

This is partial correctness over a mini semantics, not full Python-in-K. The
trusted base is the adequacy of the mini semantics for the issue's observable,
the reachability proof rules, the K toolchain, and the merge simplification
rules. Because this session forbids running K, the proof remains constructed,
not machine-checked.

## Machine-Check Commands Not Run

From the workspace root, a future machine-checking pass should run:

```sh
cd fvk
kompile mini-python-vector.k --backend haskell
kast --backend haskell vector-add-spec.k
kprove vector-add-spec.k
```

Expected result after successful machine checking: `kprove` reduces all claims
to `#Top`.

## Test Recommendation

Do not delete any tests in this benchmark. After machine-checking, a unit test
whose only assertion is the in-domain reproducer `sum([N.x, 0 * N.x]) == N.x`
would be subsumed by `SUM-REPRODUCER`, but deletion would still be only a
recommendation and is outside this task.

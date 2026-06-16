# FVK Proof

Status: constructed, not machine-checked. No Python, tests, `kompile`, or
`kprove` were run.

## Claim Summary

For integer inputs to `Colormap.__call__`, V1 establishes enough dtype
capacity in `xa` to hold the largest special lookup-table index
`self._i_bad == self.N + 2` before assigning any of the special indices. This
prevents NumPy out-of-bound integer conversion warnings and preserves the
intended special-index semantics for under, over, and bad values.

## Constructed Proof

Let:

- `N = self.N`;
- `U = self._i_under = N`;
- `O = self._i_over = N + 1`;
- `B = self._i_bad = N + 2`;
- `C0` be the maximum representable value of `xa.dtype` before V1's integer
  promotion branch;
- `C1` be the maximum representable value of `xa.dtype` after that branch.

### PO-001

V1 checks `B > C0` using `self._i_bad > np.iinfo(xa.dtype).max`.

If false, `C0 >= B`, so leaving `xa` unchanged establishes `C1 >= B`.

If true, V1 casts to `np.promote_types(xa.dtype, np.min_scalar_type(B))`.
Within the stated NumPy-domain assumption, the promoted dtype represents `B`;
therefore `C1 >= B`.

Thus `xa` can represent the largest sentinel before the sentinel assignments.

### PO-002

Because `U = N`, `O = N + 1`, and `B = N + 2`, `U <= O <= B`. From PO-001,
`C1 >= B`; therefore `C1` also represents `U` and `O`. All three assignment
right-hand sides are representable in `xa`'s dtype at assignment time.

### PO-003

The code executes the assignments in this order:

1. indices greater than `N - 1` become `O`;
2. indices less than `0` become `U`;
3. masked bad indices become `B`.

For any element, if `bad` is true, the final assignment writes `B` last. If
`bad` is false and `v > N - 1`, the over assignment writes `O` and no later
assignment applies unless `v < 0`, which cannot hold for the same signed
integer value under `N >= 0`; unsigned values also cannot satisfy `v < 0`.
If `bad` is false and `v < 0`, the under assignment writes `U`. If none of the
masks applies, the value remains `v`. This matches S-002.

### PO-004

The reported input has `N == 256`, `B == 258`, and `uint8` capacity 255.
The V1 guard therefore takes the promotion branch before any sentinel
assignment. By PO-001 and PO-002, assigning 257, 256, or 258 no longer requires
NumPy to convert an out-of-bound Python integer into `uint8`. The warning
mechanism described in the issue is removed.

### PO-005

For `0 <= v < N` and `bad == false`, all three assignment masks are false for
that element. A dtype promotion preserves the mathematical integer value, so
the lookup index remains `v`.

### PO-006

The source diff changes only the internal integer `xa` dtype before sentinel
assignment. It does not alter the public signature, return conversion,
`alpha`, `bytes`, or lookup-table access.

## K-Style Claim Skeletons

The following claim skeletons are the machine-checking target for a complete
FVK environment. They are not executed in this benchmark session.

```k
// CLAIM COLORMAP-CAPACITY
// requires N >=Int 0
// ensures  postCapacity(N +Int 2, C0) >=Int N +Int 2
```

```k
// CLAIM COLORMAP-NORMALIZE-INT
// requires N >=Int 0
// requires CAP >=Int N +Int 2
// ensures  each normalized index equals
//          bad ? N +Int 2
//              : (v >Int N -Int 1 ? N +Int 1
//                 : (v <Int 0 ? N : v))
```

```k
// CLAIM COLORMAP-FRAME
// requires 0 <=Int v andBool v <Int N andBool notBool bad
// ensures  normalizedIndex(N, v, bad) ==Int v
```

## Commands Not Run

In a complete FVK environment, the included K skeletons would be checked with:

```sh
kompile fvk/mini-colormap.k --backend haskell
kast --backend haskell fvk/colormap-call-spec.k
kprove fvk/colormap-call-spec.k
```

Expected successful machine-check result: `#Top`.

## Test Recommendation

No tests were read, run, modified, or removed. If machine checking and normal
runtime testing later become available, tests that assert no warning for
`uint8` empty arrays and correct special-index handling for small integer
dtypes would be subsumed by PO-001 through PO-004. Until then, all tests should
be kept.

## Residual Risk

This is a partial-correctness proof over the integer sentinel-normalization
slice. It does not prove termination, full NumPy semantics, or rendering
integration behavior. The main model boundary is the abstracted NumPy dtype
promotion fact in PO-001.

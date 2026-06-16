# FVK PROOF OBLIGATIONS - sympy__sympy-11618

Status: constructed, not machine-checked.

## PO-001 - General Zero-Fill Euclidean Distance

For any finite coordinate lists `A` and `B`, define:

- `coord(A, i) = A[i]` when `0 <= i < len(A)`;
- `coord(A, i) = 0` otherwise;
- `N = max(len(A), len(B))`.

`Point.distance(A, B)` must return:

```text
sqrt(sum((coord(A, i) - coord(B, i))**2 for i in range(N)))
```

V1 discharge argument:

`zip_longest(self.args, other_args, fillvalue=S.Zero)` produces exactly
`N` coordinate pairs. Each missing coordinate is `S.Zero`. The list
comprehension squares each coordinate difference, `sum` adds them, and `sqrt`
wraps the result.

Formal K claim:

`POINT-DISTANCE-GENERAL` in `fvk/point-distance-spec.k`.

## PO-002 - Reported Concrete Example

The issue example must compute:

```text
Point(2, 0).distance(Point(1, 0, 2))
= sqrt((2 - 1)**2 + (0 - 0)**2 + (0 - 2)**2)
= sqrt(5)
```

V1 discharge argument:

The coordinate pairs are `(2, 1)`, `(0, 0)`, and `(0, 2)`.

Formal K claim:

`POINT-DISTANCE-REPORTED` in `fvk/point-distance-spec.k`.

## PO-003 - Same-Dimensional Frame Condition

For any coordinate lists `A` and `B` where `len(A) == len(B)`, V1 must produce
the same formula as the prior implementation:

```text
sqrt(sum((a - b)**2 for (a, b) in zip(A, B)))
```

V1 discharge argument:

When both inputs have the same length, `zip_longest(A, B, fillvalue=0)` returns
the same sequence of coordinate pairs as `zip(A, B)`.

Formal K claim:

`POINT-DISTANCE-SAME-DIM-FRAME` in `fvk/point-distance-spec.k`.

## PO-004 - Public API Compatibility

The fix must not change the public method signature, accepted argument shape, or
result category.

V1 discharge argument:

The signature remains `distance(self, p)`. The method still accepts a `Point` or
iterable coordinate argument as before. The return remains `sqrt(sum(...))`, a
SymPy expression. The source change is limited to the coordinate-pair iterator.

Formal audit:

SPEC FS-004 and FINDINGS F-002.

## PO-005 - Honesty and Reproducibility

Because execution is prohibited, the proof must provide commands instead of
running them and must not claim machine-checked status.

Required commands:

```sh
kompile fvk/mini-python.k --backend haskell
kast --backend haskell fvk/point-distance-spec.k
kprove fvk/point-distance-spec.k
```

Expected result after a real machine check:

`#Top`.
